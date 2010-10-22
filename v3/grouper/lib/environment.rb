require 'mongoid'

class Numeric
  def to_rad
    (self * (Math::PI / 180) / 1000)
  end
end

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
    Environment.where(:client_uuid => uuid).desc(:created_at).first
  end

  def group
    Environment
      .where(:group_id => group_id)
      .only(:client_uuid, :group_id) || []
  end

  def nearby
    query = [
      ( self.gps[:longitude] || self.gps["longitude"] ),
      ( self.gps[:latitude]  || self.gps["latitude"] ),
      ( self.gps[:accuracy]  || self.gps["accuracy"] ).to_rad
    ]

    Environment
      .where({"client_uuid" => {"$ne" => self.client_uuid}})
      .near( :gps => query )
      .each.to_a
  end

  private
  def ensure_indexable
    location = {
      "longitude" => self[:gps]["longitude"],
      "latitude"  => self[:gps]["latitude"]
    }
    gps = location.merge(self[:gps])
  end

  def add_creation_time
    self[:created_at] = Time.now.to_f
  end

  def update_groups
    relevant_envs = self.nearby + [self]

    group_id = rand(1000000)
    relevant_envs.each do |e|
      e[:group_id] = group_id
      e.save
    end

    reload
  end
end
