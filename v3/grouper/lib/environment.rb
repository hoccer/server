require 'mongoid'

module Hoccer
  class Environment

    GUARANTEED_DISTANCE = 200.0
    MAX_SEARCH_DISTANCE = 5050.0
    EARTH_RADIUS        = 1000 * 6371

    include Mongoid::Document
    store_in :environments

    field :gps,         :type => Hash
    field :wifi,        :type => Hash
    field :network,     :type => Hash
    field :group_id
    field :api_key

    before_create :add_group_id, :add_creation_time, :normalize_bssids, :choose_best_location
    before_save   :ensure_indexable
    after_create  :update_groups

    def self.newest uuid
      Environment.where(:client_uuid => uuid).desc(:created_at).first
    end

    def group
      Environment
        .where({:group_id => self[:group_id], :created_at => {"$gt" => Time.now.to_i - 30} })
        .only(:client_uuid, :group_id, :latency ).to_a || []
    end

    def has_wifi
      return false unless self.wifi
      w = self.wifi.with_indifferent_access
      w[:bssids] && w[:bssids].count > 0
    end

    def has_gps
      return false unless self.gps
      g = self.gps.with_indifferent_access
      g[:latitude] && g[:longitude] && g[:accuracy]
    end

    def has_network
      return false unless self.network
      n = self.network.with_indifferent_access
      n && n[:latitude] && n[:longitude] && n[:accuracy]
    end

    def nearby_bssids
      return [] unless has_wifi

      bssids = self.wifi.with_indifferent_access[:bssids]

      return [] unless bssids
      Environment.where(
        { "created_at" => {"$gt" => Time.now.to_f - 30}}
      ).where(
        { "api_key" => api_key }
      ).any_of(
        *(bssids.map { |bssid| {"wifi.bssids" => bssid} })
      ).to_a
    end

    def nearby_gps
      return [] unless has_gps

      lon = ( gps[:longitude] || gps["longitude"] )
      lat = ( gps[:latitude]  || gps["latitude"] )
      acc = ( gps[:accuracy]  || gps["accuracy"] )

      results = Environment.db.command({
        "geoNear"     => "environments",
        "near"        => [lon.to_f, lat.to_f],
        "maxDistance" => MAX_SEARCH_DISTANCE / EARTH_RADIUS,
        "spherical" => true,
        "query" => { "api_key" => api_key, "created_at" => {"$gt" => Time.now.to_f - 30}}
      })["results"]

      results.select! do |result|
        distance = (result["dis"] * EARTH_RADIUS) # in meters
        uncerteny = [(result["obj"]["gps"]["accuracy"] + acc) * 2, MAX_SEARCH_DISTANCE].min
        distance <= [GUARANTEED_DISTANCE, uncerteny].max
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
      return unless has_gps
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
      return unless has_wifi
      wifi = self.wifi.with_indifferent_access

      bssids = wifi[:bssids]
      return unless bssids
      self.wifi[:bssids] = bssids.map do |bssid|
        bssid.gsub(/\b([A-Fa-f0-9])\b/, '0\1').downcase
      end
      self.wifi.delete("bssids")
    end

    def update_groups
      relevant_envs = self.nearby

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
      if grouped_envs and grouped_envs.count > 1
        #puts "grouped <#{grouped_envs.map {|e|  e.client_uuid rescue "<unknown>"} }>"
      end

      reload
    end

    def choose_best_location
      if has_network
        n = self.network.with_indifferent_access
        if not has_gps
          self.gps = n
        elsif n[:timestamp] > self.gps.with_indifferent_access[:timestamp]
          self.gps = n
        end
      end
    end
  end
end
