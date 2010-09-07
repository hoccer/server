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

    end

    def initialize options
      @actions  = {}
      @uuid     = UUID.generate(:compact)

      unless options.empty?
        @environment = options[:environment]
      end
    end

    def all_in_group
      @@pool.values.select do |client|
        client.group_id == self.group_id
      end
    end

    def neighbors
      @@pool.values.select do |client|
        client.group_id == self.group_id && client.uuid != self.uuid
      end
    end

    def sender?
      @mode == :sender
    end

    def rebuild_groups
      @@pool.values.each do |other_client|
        if other_client.environment[:foo] == "bar"
          self.group_id, other_client.group_id = 1,1
        end
      end
    end


  end

  class ClientAlreadyExists < ArgumentError; end
end
