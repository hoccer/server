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

      def create options = {}
        client = self.new options

        if @@pool[client.uuid].nil?
          @@pool[client.uuid] = client
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
