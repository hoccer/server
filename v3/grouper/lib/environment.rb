require 'mongoid'

EARTH_RADIUS = 1000 * 6371

class Numeric
  def to_rad
    (self * (Math::PI / 180) / 1000)
  end
end

class Environment

  include Mongoid::Document

  field :gps,     :type => Hash
  field :bssids,  :type => Array
  field :network, :type => Hash

  before_create :ensure_indexable
  before_create :add_creation_time
  after_create  :update_groups

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
      .where(:group_id => self[:group_id])
      .only(:client_uuid, :group_id) || []
  end

  def nearby_bssids
    return [] unless self.bssids

    Environment.any_of(
      *self.bssids.map { |bssid| {:bssids => bssid} }
    ).to_a
  end

  def nearby_gps
    gps = best_location
    return [] unless gps

    lon = ( gps[:longitude] || gps["longitude"] )
    lat = ( gps[:latitude]  || gps["latitude"] )
    acc = ( gps[:accuracy]  || gps["accuracy"] )

    results = Environment.db.command({
      "geoNear"     => "environments",
      "near"        => [lon.to_f, lat.to_f],
      "maxDistance" => 0.00078480615288,
      "spherical" => true
    })["results"]

    results.select! do |result|
      (result["dis"] * EARTH_RADIUS) < ((result["obj"]["gps"]["accuracy"] + acc) * 2)
    end

    results.map do |result|
      Mongoid::Factory.build(Environment, result["obj"])
    end
  end
  
  def nearby
    nearby_gps | nearby_bssids
  end

  private
  def ensure_indexable
    return nil unless self.gps

    begin
      location = {
        "longitude" => ( self.gps["longitude"] || self.gps[:longitude] ),
        "latitude"  => ( self.gps["latitude"]  || self.gps[:latitude] )
      }
      self.gps = location.merge(self.gps)
    rescue => e
      puts "!!!!!!! Panic: #{e}"
      self.gps
    end
  end

  def add_creation_time
    self[:created_at] = Time.now.to_f
  end

  def update_groups
    relevant_envs = self.nearby | self.nearby_bssids

    grouped_envs  = relevant_envs.inject([]) do |result, element|
      element.group.each do |group_env|
        unless result.include?( group_env )
          result << group_env
        end
      end
      result
    end

    new_group_id = rand(Time.now.to_i)
    ( grouped_envs | relevant_envs ).each do |foobar|
      foobar[:group_id] = new_group_id
      foobar.save
    end

    reload
  end
  
  def best_location
    if gps && !network 
      return gps
    end
    
    if !gps && network
      return network
    end
    
  end
end
