module Hoccer

  class Client

    @@requests = {}

    def initialize options = {}
      defaults = {
        :uuid         => UUID.generate(:compact),
        :dna          => { :client => "spikey" },
        :environment  => {},
        :action       => nil,
        :payload      => {},
        :mode         => nil,
        :group_id     => nil
      }

      options = defaults.merge( options )

      options.each do |key, value|
        Client.send :attr_accessor, key
        instance_variable_set("@#{key}", value)
      end
    end

    def self.create options = {}
      client = Client.new options
      client.save
      client
    end

    def self.collection
      Hoccer.db.collection('clients')
    end

    def self.first options, &block
      collection.first( options ) do |res|
        if res
          yield Client.new res
        else
          yield nil
        end
      end
    end

    def self.each_with_request
      clients = @@requests.select do |client_uuid, request|
        request
      end

      puts "!!!! #{clients.inspect}"
      query = { :uuid => {"$in" => clients.map {|c| c[0] }} }

      Client.collection.find(query) do |res|
        puts "pppppppppp #{res.inspect}"
        res.map { |r| Client.new(r)}.each do |client|
          yield client
        end
      end
    end

    def request= request_object
      @@requests[uuid] = request_object
    end

    def request
      @@requests[uuid]
    end

    def attributes
      instance_variables.inject({}) do |result, name|
        result[ name.to_s.delete("@") ] = instance_variable_get( name )
        result
      end
    end

    def update_environment environment
      Hoccer.db.collection('environments').update(
        {:client_uuid => uuid},
        environment.merge(:client_uuid => uuid),
        :upsert => true
      )

      rebuild_groups
    end

    def rebuild_groups
      query = { :gps =>  {"$near" => [32.22, 88.74] , "$maxDistance" => 200.to_rad } }
      Hoccer.db.collection('environments').find( query ) do |results|
        group_id = rand(2**32)
        results.each do |result|
          Hoccer.db.collection('environments').update(
            {:client_uuid => uuid}, {"$set" => {:group_id => group_id}}
          )
        end
      end
    end

    def each_in_group &block
      Client.collection.find do |results|
        clients = results.map { |r| Client.new( r ) }
        clients.each do |client|
          yield client
        end
      end
    end

    def update_action action, payload = nil
      @action = action.to_s
      @payload = payload

      if payload
        @mode = :sender
      else
        @mode = :receiver
      end

      puts attributes
      save
    end

    def save
      puts attributes.inspect
      if attributes["_id"]
        Client.collection.update( {:_id => attributes["_id"]}, attributes )
      else
        Client.collection.insert( attributes )
      end
    end

    def environment
      Hoccer.db.collection("environments").first(:client_uuid => uuid) do |res|
        return res
      end
    end

    def clientalize mongo_result
      if mongo_result.is_a?( Array )
        mongo_result.map { |r| Client.new( r ) }
      elsif mongo_result.is_a?( String )
        Client.new( mongo_result )
      end
    end

    def self.requests_for_clients clients
      clients.map { |c| @@requests[c.uuid] }
    end

  end

end


__END__
module Hoccer

  class Client

    attr_accessor :uuid,
                  :request,
                  :environment,
                  :group_id,
                  :actions,
                  :mode

    @@pool    = {}
    @@groups  = {}

    class << self

      def connection
        Hoccer.db.connection('clients')
      end

      def create options = {}
        options[:uuid] ||= UUID.generate(:compact)

        connection.find(:uuid => options[:uuid]) do |res|
          puts res.inspect
          if res.empty?
            connection.insert(
        else
          raise ClientAlreadyExists
        end
      end

      def find uuid
        @@pool[uuid]
      end

      def delete_all
        @@pool = {}
      end

      # Calculates the distance in meters between two peers
      def distance loc_a, loc_b
        if ( loc_a.nil? || loc_b.nil? )
          return nil
        end

        distance_latitude   = (loc_a["latitude"]   - loc_b["latitude"]).to_rad
        distance_longitude  = (loc_a["longitude"]  - loc_b["longitude"]).to_rad

        a = (Math.sin(distance_latitude/2) ** 2)  +
            (Math.cos(loc_a["latitude"].to_rad)   *
             Math.cos(loc_b["latitude"].to_rad))  *
            (Math.sin(distance_longitude/2) ** 2)

        if a < 0 || a > 1
          puts(
            #"!!!!! #{a}; #{peer_a.latitude}; #{peer_a.longitude}" +
            "Something went wrong calculationg the distance"
            #"#{peer_b.latitude}; #{peer_b.longitude}"
          )
        end

        c = 2 * Math.atan2(
          Math.sqrt(a),
          Math.sqrt(1-a)
        )

        distance = 6367516 * c

      end
    end

    def initialize options
      @uuid     = UUID.generate(:compact)
      @actions  = ActionStore.new(@uuid)

      unless options.empty?
        @environment = options[:environment]
      end
    end

    def all_in_group
      @@pool.values.select do |client|
        !client.group_id.nil? &&  client.group_id == self.group_id
      end
    end

    def neighbors
      @@pool.values.select do |client|
        !client.group_id.nil? && client.group_id == self.group_id && client.uuid != self.uuid
      end
    end

    def sender?
      @mode == :sender
    end

    def receiver?
      @mode == :receiver
    end

    def rebuild_groups
      @@pool.values.each do |other_client|
        next if other_client == self
        if nearby? other_client
          new_group_id = rand(2**16)
          self.group_id, other_client.group_id = new_group_id, new_group_id
        end
      end
    end

    def nearby? other_client
      if self.environment && other_client.environment
        distance = Client.distance(
          self.environment["gps"],
          other_client.environment["gps"]
        )
        distance && distance < 1000.0
      else
        false
      end
    end

    def verify_group action
      clients   = all_in_group.select { |c| c.sender? && c.actions[action] }
      receiver  = all_in_group.select { |c| c.receiver? && c.actions[action] }

      if clients.size >= 1 && receiver.size >= 1
        all_in_group.each do |client|
          if client.request
            puts "Y A Y"

            data_list = clients.map do |client|
              client.actions[action][:payload]
            end

            client.request.body { data_list.to_json }
            client.request = nil
          end
        end
      end
    end

  end

  class ClientAlreadyExists < ArgumentError; end
end
