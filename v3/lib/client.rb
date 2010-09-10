require 'ruby-debug'
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
        my_lon    = environment["gps"]["longitude"].to_i rescue nil
        my_lat    = environment["gps"]["latitude"].to_i  rescue nil

        other_lon = other_client.environment["gps"]["longitude"].to_i rescue nil
        other_lat = other_client.environment["gps"]["latitude"].to_i  rescue nil

        return if [my_lon, my_lat, other_lon, other_lat].any?(&:nil?)
        my_lon == other_lon && my_lat == other_lat
      else
        false
      end
    end

  end

  class ClientAlreadyExists < ArgumentError; end
end
