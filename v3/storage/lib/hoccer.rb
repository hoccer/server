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
        collection.insert( payload )
      end

      body { "yeag" }
    end

    apost %r{/query} do
      payload = JSON.parse(request.body.read)

      puts payload.inspect
      @@db ||= EM::Mongo::Connection.new.db('db')
      collection = @@db.collection('test')

      if box = payload["box"]
        EM.next_tick do
          collection.find({"environment.gps" => {"$within" => {"$box" => box}}}) do |res|
            new_results = res.map do |item|
              item.delete("_id")
              item
            end
            body { new_results.to_json }
          end
        end
      else
        center    = payload["gps"]["longitude"], payload["gps"]["latitude"]
        radius    = (payload["gps"]["accuracy"].to_f/6371)
        EM.next_tick do
          collection.find({"environment.gps" => {"$within" => { "$center" => [center, radius]}}}) do |res|
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
