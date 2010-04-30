# require 'mongo_mapper'
# 
# class Places
#   include MongoMapper::Document
#   MongoMapper.database = "events"
#   connection Mongo::Connection.new('localhost')
#   set_database_name 'events'
#   
#   def self.import_from_events
#     
#     Event.find_in_batches do |grouped_events|
#       grouped_events.each do |event|
#         place = self.new(:location => [event.latitude, event.longitude])
#         place.save
#       end
#     end
#   end
#   
# end