require 'ruby-debug'
module GeoStore

  class App < Sinatra::Base
    register Sinatra::Async

    @@db = nil

    apost %r{/store} do
      payload = JSON.parse(request.body.read)
      puts payload.inspect
      @@db ||= EM::Mongo::Connection.new.db('db')
      collection = @@db.collection('test')
      EM.next_tick do
        payload["lifetime"]  ||= 1800
        payload["ending_at"] = (Time.now.to_i + payload["lifetime"].abs)
        result = collection.insert( payload )

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
      payload = JSON.parse(request.body.read)

      puts payload.inspect
      collection = db.collection('test')

      EM.next_tick do
        query = {}
        query["ending_at"] = {"$gt" => (Time.now.to_i)}
        query["params"] = payload["find"] if payload["find"]

        if box = payload["box"]
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
        
        puts "query: #{query}"
        
        collection.find( query ) do |res|
          new_results = res.map do |item|
            item.delete("_id")
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
