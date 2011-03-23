require 'ruby-debug'

module Hoccer
  class Client

    UUID_PATTERN = /[a-zA-Z0-9\-]{36,36}/

    attr_accessor :environment,
                  :group,
                  :action,
                  :body_buffer,
                  :request,
                  :error,
                  :uuid,
                  :hoccability

    @@clients = {}

    def initialize connection
      @request      = connection
      @uuid         = connection.request.path_info.match(UUID_PATTERN)[0]
      @body_buffer  = connection.request.body.read
      @environment  = { :api_key => connection.params["api_key"] }
      @error        = nil
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

    def add_action name, role
      params = parse_body

      action  = Action.new(
        :name     => name,
        :type     => role,
        :payload  => params,
        :request  => request,
        :uuid     => uuid,
        :api_key  => environment[:api_key]
      )

    end

  end
end
