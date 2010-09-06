module Hoccer

  class Client

    attr_accessor :uuid, :request, :environment

    @@pool = {}

    def initialize options = {}

      if options.empty?
        @uuid = UUID.generate(:compact)
      end

    end

    class << self

      def create
        client = self.new

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

  end

  class ClientAlreadyExists < ArgumentError; end
end
