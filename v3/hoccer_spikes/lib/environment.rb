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
    near_by = Environment.near( :gps => gps )   

    puts "updating group_id"
    group_id = rand(1000000) 
    near_by.each do |e|
      e[:group_id] = group_id
      e.save
    end
    
    reload
  end

  def group
    Environment
      .where(:group_id => group_id)
      .only(:client_uuid, :group_id)
      .all
  end

end
