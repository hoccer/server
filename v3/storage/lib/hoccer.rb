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

    apost %r{/query} do
      payload = JSON.parse(request.body.read)

      puts payload.inspect
      @@db ||= EM::Mongo::Connection.new.db('db')
      collection = @@db.collection('test')

      if box = payload["box"]
        EM.next_tick do
          query = {
            "environment.gps" => {
              "$within" => {"$box" => box}
            },
            "ending_at" => {"$lt" => (Time.now.to_i)}
          }

          collection.find( query ) do |res|
            new_results = res.map do |item|
              item.delete("_id")
              item
            end
            body { new_results.to_json }
          end
        end
      else
        EM.next_tick do
          center    = payload["gps"]["longitude"], payload["gps"]["latitude"]
          radius    = (payload["gps"]["accuracy"].to_f/6371)
          query     = {
            "environment.gps" => {
              "$within" => { "$center" => [center, radius] }
            },
            "ending_at" => {"$lt" => (Time.now.to_i)}
          }
          collection.find( query ) do |res|
            new_results = res.map do |item|
              item.delete("_id")
              item
            end
            body { new_results.to_json }
          end
        end
      end
    end

  end

end
