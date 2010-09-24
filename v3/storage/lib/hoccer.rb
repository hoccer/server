module GeoStore

  class App < Sinatra::Base
    register Sinatra::Async

    @@db = nil

    def authorized_request &block
      EM.next_tick do
        db.collection('users').first("api_key" => params["apiKey"]) do |res|
          ahalt 432 if res.nil?

          signature = params.delete("signature")
          uri       = env['REQUEST_URI'].gsub(/\&signature\=.+$/, "")

          digestor = Digest::HMAC.new( res["shared_secret"], Digest::SHA1 )
          computed_signature = digestor.base64digest(uri)

          if signature == computed_signature
            block.call
          else
            ahalt 401
          end
        end
      end
    end

    apost %r{/store} do
      authorized_request do
        payload = JSON.parse(request.body.read)
        payload["lifetime"]  ||= 1800
        payload["ending_at"] = (Time.now.to_i + payload["lifetime"].abs)

        puts payload.inspect
        result = db.collection('test').insert( payload )

        response  = { :url => "/store/#{ result["_id"].to_s }" }
        ahalt 201, {'Content-Type' => 'application/json'}, response.to_json
      end
    end

    delete %r{/store/([a-f0-9]{24,24}$)} do |uuid|
      collection = db.collection('test')

      if collection.remove( { :_id => BSON::ObjectId.from_string(uuid) } )
        halt 200
      else
        halt 404
      end
    end

    apost %r{/query} do
      authorized_request do
        payload = JSON.parse(request.body.read)

        puts payload.inspect
        collection = db.collection('test')

        query = {}
        query["ending_at"] = {"$gt" => (Time.now.to_i)}
        query["data"] = payload["conditions"] if payload["conditions"]

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
      @@db ||= EM::Mongo::Connection.new.db('db')
    end

  end

end
