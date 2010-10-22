require 'mongoid'

class Environment

  include Mongoid::Document

  before_save :ensure_indexable, :add_creation_time
  after_create :update_groups

  Mongoid.configure do |config|
    name = "hoccer_development"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = true
  end

  def self.newest uuid
    Environment.where(:client_uuid => uuid).desc(:created_at).last
  end

  def group
    Environment
      .where(:group_id => group_id)
      .only(:client_uuid, :group_id) || []
  end

  private
  def ensure_indexable
    location = { "longitude" => self[:gps]["longitude"], "latitude" => self[:gps]["latitude"]}
    gps = location.merge(self[:gps])
  end

  def add_creation_time
    self[:created_at] = Time.now.to_f
  end

  def update_groups
    near_by = Environment.near( :gps => gps )

    group_id = rand(1000000)
    near_by.each do |e|
      e[:group_id] = group_id
      e.save
    end

    reload
  end
end
