require 'ruby-debug'

module Hoccer
  class Client

    UUID_PATTERN = /[a-zA-Z0-9\-]{36,36}/

    attr_accessor :environment,
                  :action,
                  :body_buffer,
                  :request,
                  :error,
                  :uuid,
                  :hoccability

    @@clients = {}

    def initialize connection
      @request          = connection
      @uuid             = connection.request.path_info.match(UUID_PATTERN)[0]
      @body_buffer      = connection.request.body.read
      @environment      = { :api_key => connection.params["api_key"] }
      @error            = nil

      @@clients[@uuid]  = self
    end

    def parse_body
      begin
        @last_body = JSON.parse( @body_buffer )
      rescue => e
        @errors = e.message
        false
      end
    end

    def info &block
      em_get( "/clients/#{uuid}" ) { |response| block.call( response ) }
    end

    def find
      @@clients[uuid]
    end

    def self.find_all_by_uuids uuids
      uuids.inject([]) do |result, uuid|
        result << @@clients[uuid]
      end
    end

    def find_or_create uuid
      @@clients[uuid] ||= Client.new( uuid )
    end

    def update_environment &block
      @environment.merge!( parse_body )

      em_put( "/clients/#{uuid}/environment", @environment.to_json ) do |response|
        block.call( response )
      end
    end

    def update_worldmap
      if data = (@environment["gps"] || @environment["network"])
        http = EM::Protocols::HttpClient.request(
          :host => "localhost",
          :port => 8090,
          :verb => 'PUT',
          :request => "/hoc",
          :content => @environment.to_json
        )
      end
    end

    def async_group &block
      em_get( "/clients/#{uuid}/group") do |response|
        group = Group.new( response[:content] )
        block.call( group )
      end
    end

    def add_action name, role

      action  = Action.create(
        :name     => name,
        :type     => role,
        :payload  => parse_body,
        :waiting  => ( request.params['waiting'] || false ),
        :request  => request,
        :uuid     => uuid,
        :api_key  => environment[:api_key]
      )

      verify_group
    end

    def verify_group
      async_group do |group|
        group.latency

        if group.size < 2 && !action[:waiting]
          action.invalidate
        end
      end
    end


  end
end
