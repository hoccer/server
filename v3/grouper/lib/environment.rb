require 'mongoid'

EARTH_RADIUS = 1000 * 6371

module Hoccer
  class Environment

    include Mongoid::Document
    store_in :environments

    field :gps,         :type => Hash
    field :wifi,        :type => Hash
    field :network,     :type => Hash
    field :group_id

    before_create :add_group_id, :add_creation_time, :normalize_bssids
    before_save   :ensure_indexable
    after_create  :update_groups

    def self.newest uuid
      Environment.where(:client_uuid => uuid).desc(:created_at).first
    end

    def group
      puts "<#{self[:client_uuid]}> is looking for group #{self[:group_id]}"

      Environment
        .where({:group_id => self[:group_id], :created_at => {"$gt" => Time.now.to_i - 30} })
        .only(:client_uuid, :group_id).to_a || []
    end

    def nearby_bssids
      return [] unless self.wifi

      bssids = self.wifi[:bssids] || self.wifi["bssids"]
      Environment.any_of(
        *(bssids.map { |bssid| {"wifi.bssids" => bssid} })
      ).to_a
    end

    def nearby_gps
      return [] unless gps

      lon = ( gps[:longitude] || gps["longitude"] )
      lat = ( gps[:latitude]  || gps["latitude"] )
      acc = ( gps[:accuracy]  || gps["accuracy"] )

      results = Environment.db.command({
        "geoNear"     => "environments",
        "near"        => [lon.to_f, lat.to_f],
        "maxDistance" => 0.00078480615288,
        "spherical" => true,
        "query" => { "created_at" => {"$gt" => Time.now.to_f - 30}}
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

    def normalize_bssids
      return unless self.wifi

      bssids = self.wifi[:bssids] || self.wifi["bssids"]
      self.wifi[:bssids] = bssids.map do |bssid| 
        bssid.gsub(/\b([A-Fa-f0-9])\b/, '0\1').downcase
      end
    end

    def update_groups
      puts "updating client <#{self[:client_uuid]}>"
      relevant_envs = self.nearby | self.nearby_bssids

      grouped_envs = relevant_envs.inject([]) do |result, element|
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
end
