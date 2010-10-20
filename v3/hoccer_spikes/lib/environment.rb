require 'mongoid'

class Environment

  include Mongoid::Document

  after_create :update_groups

  Mongoid.configure do |config|
    name = "hoccer_development"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = true
  end

  def update_groups
    # client = Environment.where(:client_uuid => self["client_uuid"]).first
    #     puts "client #{client.inspect}"
    # near_by = self.class
    #    .find( { :gps.near => [13, 52] } )
    #    .all
       
    near_by = Environment.near( :gps => gps )   

    puts "updating group_id"
    near_by.each do |e|
      e[:group_id] = 12
      e.save
    end
    
    reload
  end



end
