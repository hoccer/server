require 'mongoid'

EARTH_RADIUS = 1000 * 6371

class Numeric
  def to_rad
    (self * (Math::PI / 180) / 1000)
  end
end

class Environment

  include Mongoid::Document

  field :gps,         :type => Hash
  field :wifi,        :type => Hash
  field :network,     :type => Hash
  field :created_at,  :type => Time

  before_create :add_group_id, :add_creation_time
  before_save   :ensure_indexable
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
    puts "looking for group: #{self[:group_id]}"

    Environment
      .where({:group_id => self[:group_id], :created_at => {"$gt" => Time.now.to_i - 120} })
      .only(:client_uuid, :group_id).to_a || []
  end

  def nearby_bssids
    return [] unless self.bssids

    Environment.any_of(
      *self.bssids.map { |bssid| {:bssids => bssid} }
    ).to_a
  end

  def nearby_gps
    #gps = self.gps
    return [] unless gps

    lon = ( gps[:longitude] || gps["longitude"] )
    lat = ( gps[:latitude]  || gps["latitude"] )
    acc = ( gps[:accuracy]  || gps["accuracy"] )

    results = Environment.db.command({
      "geoNear"     => "environments",
      "near"        => [lon.to_f, lat.to_f],
      "maxDistance" => 0.00078480615288,
      "spherical" => true,
      "query" => { "created_at" => {"$gt" => Time.now.to_f - 120}}
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
    return unless self.gps
    begin
      location = {
        "longitude" => ( self.gps["longitude"] || self.gps[:longitude] ),
        "latitude"  => ( self.gps["latitude"]  || self.gps[:latitude] )
      }
      self.gps = location.merge(self.gps)

    rescue => e
      puts "!!!!!!! Panic: #{e}"
    end
  end

  def add_group_id
    self[:group_id] = rand(Time.now.to_i)
  end

  def add_creation_time
    self[:created_at] = Time.now.to_f
  end

  def update_groups
    puts "updating ><<<<<>>>"
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
    if !gps && !network
      nil
    elsif gps && !network
      gps
    elsif !gps && network
      network
    elsif network[:timestamp] < gps[:timestamp]
      network
    else
      gps
    end
  end
end
