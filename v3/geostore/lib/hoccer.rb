module GeoStore

  class App < Sinatra::Base
    register Sinatra::Async

    @@db = nil

    def authorized_request &block
      EM.next_tick do
        collection =  db.collection('accounts')
        collection.first("api_key" => params["apiKey"]) do |account|
          if account.nil?
            ahalt 401
          else
            signature = params.delete("signature")
            uri       = env['REQUEST_URI'].gsub(/\&signature\=.+$/, "")

            digestor = Digest::HMAC.new(account["shared_secret"], Digest::SHA1)
            computed_signature = digestor.base64digest(uri)

            if signature == computed_signature
              block.call( account )
            else
              ahalt 401
            end
          end
        end
      end
    end

    apost %r{/store} do
      authorized_request do |account|
        payload = JSON.parse(request.body.read)
        payload["lifetime"]   ||= 1800
        payload["ending_at"]  = (Time.now.to_i + payload["lifetime"].abs)
        payload["account_id"] = account["_id"]

        puts payload.inspect
        result = db.collection('data').insert( payload )

        response  = { :url => "/store/#{ result["_id"].to_s }" }
        ahalt 201, {'Content-Type' => 'application/json'}, response.to_json
      end
    end

    adelete %r{/store/([a-f0-9]{24,24}$)} do |uuid|
      authorized_request do |account|
        collection = db.collection('data')

        if collection.remove( {
          :_id => BSON::ObjectId.from_string(uuid),
          :account_id => account["_id"]
        } )
          ahalt 200
        else
          ahalt 404
        end
      end
    end

    apost %r{/query} do
      authorized_request do |account|
        payload = JSON.parse(request.body.read)

        puts payload.inspect
        collection = db.collection('data')

        query = {}
        query["ending_at"]  = {"$gt" => (Time.now.to_i)}
        query["data"]       = payload["conditions"] if payload["conditions"]
        query["account_id"] = account["_id"]

        if box = payload["bbox"]
          query["environment.gps"] = {
            "$within" => {"$box" => box}
          }
        else
          center    = payload["gps"]["longitude"], payload["gps"]["latitude"]
          radius    = (payload["gps"]["accuracy"].to_f/6371)
          query["environment.gps"] = {
            "$within" => { "$center" => [center, radius] }
          }
        end

        collection.find( query ) do |res|
          new_results = res.map do |item|
            item["_id"] = item["_id"].to_s
            item
          end
          body { new_results.to_json }
        end
      end
    end

    def db
      @@db ||= EM::Mongo::Connection.new.db('hoccer_v3')
    end

  end

end
