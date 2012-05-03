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
    field :mdns,        :type => Hash
    field :network,     :type => Hash
    field :group_id
    field :api_key
    field :pubkey_id

    attr_accessor :grouped_envs


    before_create :add_group_id, :add_creation_time, :normalize_bssids
    before_save   :choose_best_location, :ensure_indexable, :remove_empty_selected_list, :add_pubkey_id
    after_create  :update_groups

    # get newest (should be only) entry for client uuid

    def self.newest uuid
      Environment.where(:client_uuid => uuid).desc(:created_at).first
    end

    # all clients with the same group id and environment update in the last 40s

    def all_in_group
      Environment
        .where({:group_id => self[:group_id], :created_at => {"$gt" => Time.now.to_i - 40} })
        .order_by([:client_uuid, :asc])
        .only(:client_uuid, :group_id, :latency, :client_name, :selected_clients, :pubkey, :pubkey_id ).to_a || []
    end

    # all clients with the same group id and environment update in the last 40s
    # filtered for (mutually) selected clients

    def group

      envs = nil
      if self[:selected_clients].nil? || self[:selected_clients].empty?
        envs = Environment
          .where({
            :group_id => self[:group_id],
            :created_at => { "$gt" => Time.now.to_i - 40 }
           })
           .any_of(
               { :selected_clients => nil },
               { :selected_clients => self[:client_uuid] }
            )
          .order_by([:client_uuid, :asc])
          .only(:client_uuid, :group_id, :latency, :client_name, :selected_clients, :pubkey, :pubkey_id ).to_a || []
      else
        envs = Environment
          .where({
            :group_id => self[:group_id],
            :created_at => { "$gt" => Time.now.to_i - 40 }
           })
          .any_of(
              { :selected_clients => nil },
              { :selected_clients => self[:client_uuid] }
           )
          .any_in(  :client_uuid => self[:selected_clients]  )
          .order_by([:client_uuid, :asc])
          .only(:client_uuid, :group_id, :latency, :client_name, :selected_clients, :pubkey, :pubkey_id ).to_a || []

          envs << self unless envs.empty?
      end

      envs
    end

    # whether client has wifi/gps/network information

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

    def has_mdns
      return false unless self.mdns
      m = self.mdns.with_indifferent_access
      m[:own_id] && m[:seen_ids] && m[seen_ids].count > 0
    end

    def has_network
      return false unless self.network
      n = self.network.with_indifferent_access
      n && n[:latitude] && n[:longitude] && n[:accuracy]
    end

    # all clients sharing a wifi bssid with environment update in the last 30s

    def nearby_bssids
      return [] unless has_wifi

      bssids = self.wifi.with_indifferent_access[:bssids]

      # if api key hoccer compatible: only clients with hoccer compatible api keys
      # if not: only clients with same api key

      if hoccer_compatible?
        query = { "api_key" => { "$in" => hoccer_compatible_api_keys } }
      else
        query = { "api_key" => api_key }
      end

      # environment update in last 30s and sharing a bssid

      return [] unless bssids
      Environment.where(
        { "created_at" => {"$gt" => Time.now.to_f - 30}}
      ).where(
        query
      ).any_of(
        *(bssids.map { |bssid| {"wifi.bssids" => bssid} })
      ).to_a
    end

    # all clients that have seen our mdns ID within the last 30s

    def nearby_mdns
      return [] unless has_mdns

      own_id = self.mdns.with_indifferent_access[:own_id]
      seen_ids = self.mdns.with_indifferent_access[:seen_ids]

      # if api key hoccer compatible: only clients with hoccer compatible api keys
      # if not: only clients with same api key

      if hoccer_compatible?
        query = { "api_key" => { "$in" => hoccer_compatible_api_keys } }
      else
        query = { "api_key" => api_key }
      end

      # environment update in last 30s and sharing a bssid

      return [] unless own_id

      puts "client has mdns.own_id #{own_id}"
      puts "client has mdns.seen_ids #{seen_ids}"

      r = Environment.where(
        { "created_at" => {"$gt" => Time.now.to_f - 30}}
      ).where(
        query
      ).where(
        { "mdns.seen_ids" => own_id }
      ).to_a

      puts "query returned clients #{r}"

      r
    end

    # all clients in geographic proximity (according to gps data) with environment update in the last 30s
    # defined as all clients within GUARANTEED_DISTANCE
    # takes accuracy into account, but does not look further than MAX_SEARCH_DISTANCE

    def nearby_gps
      return [] unless has_gps

      lon = ( gps[:longitude] || gps["longitude"] )
      lat = ( gps[:latitude]  || gps["latitude"] )
      acc = ( gps[:accuracy]  || gps["accuracy"] )

      # look for clients with environment updates in the last 30s
      # if api key hoccer compatible: only clients with hoccer compatible api keys
      # if not: only clients with same api key

      if hoccer_compatible?
        query = {
          "api_key" => {"$in" => hoccer_compatible_api_keys},
          "created_at" => {"$gt" => Time.now.to_f - 30}
        }
      else
        query = {
          "api_key" => api_key,
          "created_at" => {"$gt" => Time.now.to_f - 30}
        }
      end

      # all such clients within MAX_SEARCH_DISTANCE meters

      results = Environment.db.command({
        "geoNear"     => "environments",
        "near"        => [lon.to_f, lat.to_f],
        "maxDistance" => MAX_SEARCH_DISTANCE / EARTH_RADIUS,
        "spherical" => true,
        "query" => query
      })["results"]

      # get nearby clients

      results.select! do |result|
        distance = (result["dis"] * EARTH_RADIUS) # in meters

        # maximal distance given by gps for two clients in the same position (according to accuracy), but at most MAX_SEARCH_DISTANCE

        uncerteny = [(result["obj"]["gps"]["accuracy"] + acc) * 2, MAX_SEARCH_DISTANCE].min

        # clients within that distance or GUARANTEED_DISTANCE
 
        distance <= [GUARANTEED_DISTANCE, uncerteny].max
      end

      # return clients

      results.map do |result|
        Mongoid::Factory.build(Environment, result["obj"])
      end
    end

    # nearby clients (determined by gps, wifi and mdns)

    def nearby
      nearby_gps | nearby_bssids | nearby_mdns
    end

    # whether the client's api key is hoccer compatible

    def hoccer_compatible?
      $db  ||= Mongo::Connection.new.db('hoccer_accounts')
      coll = $db.collection('accounts')

      0 < coll.find(
        :api_key            => api_key,
        :hoccer_compatible  => true
      ).count
    end

    # all hoccer compatible api keys

    def hoccer_compatible_api_keys
      $db  ||= Mongo::Connection.new.db('hoccer_accounts')
      coll = $db.collection('accounts')

      coll.find({:hoccer_compatible => true}, :fields => :api_key).map do |k|
        k["api_key"]
      end
    end

    # update group of client
    # called after creation, i.e. after every environment update
    # new group: all nearby clients and all clients previously sharing a group with a nearby client
    # changes group id for all clients in the new group

    def update_groups

      # get nearby clients

      relevant_envs = self.nearby

      # all clients in the same group as a nearby client

      @grouped_envs = relevant_envs.inject([]) do |result, element|
        element.all_in_group.each do |group_env|
          unless result.include?( group_env )
            result << group_env
          end
        end
        result
      end

      # create new group id and assign to all clients in the new group

      new_group_id = rand(Time.now.to_i)

      group_uuids = @grouped_envs.map { |e| e.client_uuid }
      puts "creating new group with id #{new_group_id} and clients #{group_uuids.inspect}"

      ( @grouped_envs | relevant_envs ).each do |foobar|
        foobar[:group_id] = new_group_id
        foobar.save
      end

      reload
    end

    # add group id (called before creation)

    def add_group_id
      self[:group_id] = rand(Time.now.to_i)
    end

    private

    # remove list of selected clients if empty (called before saving)

    def remove_empty_selected_list
      if self[:selected_clients].nil? || self[:selected_clients].empty?
        self.remove_attribute(:selected_clients)
      end
    end

    # ensure gps contains "longitude" and "latitude" (called before saving)

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

    # add time of creation (called before creation)

    def add_creation_time
      self[:created_at] = Time.now.to_f
    end

    # add hash id for public key (called before saving)
    
    def add_pubkey_id
      if self[:pubkey]
        self[:pubkey_id] = Digest::SHA256.hexdigest(self[:pubkey])[0..7]
      end
    end

    # normalize bssids (called before creation)
    # e.g. 1:23:4F:C:89:AB -> 01:23:4f:0c:89:ab

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

    # write best location data in gps (called before saving)
    # if no location data from gps: network, if location data from both: most current

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
