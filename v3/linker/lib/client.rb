require 'ruby-debug'

module Hoccer
  class Client

    UUID_PATTERN = /[a-zA-Z0-9\-]{36,36}/

    attr_accessor :environment,
                  :action,
                  :error,
                  :uuid,
                  :hoccability,
                  :waiting,
                  :body_content

    @@clients = {}

    def initialize connection
      @uuid             = connection.request.path_info.match(UUID_PATTERN)[0]

      @@clients[@uuid]  = self
    end
    
    def update_connection connection
      @uuid             = connection.request.path_info.match(UUID_PATTERN)[0]
      @body_content     = nil
      @body_buffer      = connection.request.body.read
      @environment      = { :api_key => connection.params["api_key"] }
      @error            = nil
    end

    def parse_body
      begin
        @body_content || JSON.parse( @body_buffer )
      rescue => e
        @errors = e.message
        false
      end
    end

    def info &block
      em_get( "/clients/#{uuid}" ) { |response| block.call( response ) }
    end

    def self.find uuid
      @@clients[uuid]
    end

    def self.find_all_by_uuids uuids
      uuids.inject([]) do |result, uuid|
        result << @@clients[uuid]
      end
    end

    def self.find_or_create connection
      uuid = connection.request.path_info.match(UUID_PATTERN)[0]
      
      @@clients[uuid] ||= Client.new( connection )
    end

    def update_environment &block
      @environment.merge!( parse_body )

      em_put( "/clients/#{uuid}/environment", @environment.to_json ) do |response|
        block.call( response )
        
        content = JSON.parse( response[:content] )
        ids = content["group"].map { |info| info["id"] }
        
        Client.find_all_by_uuids( ids ).each do |client|
          client.update_grouped( content["group"] ) if client
        end
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
    
    def delete &block
      async_group do |group|
        em_delete("/clients/#{uuid}/delete") do |response|
          content = JSON.parse(response[:content])
          block.call(content)
          
          changed_clients = Client.find_all_by_uuids(content)
          changed_clients.each do |client|
            client.async_group do |new_group|
              client.update_grouped( new_group.client_infos )
            end
          end
        end
      end
    end
    
    def waiting?
      @waiting
    end

    def async_group &block
      em_get( "/clients/#{uuid}/group") do |response|
        group = Group.new( response[:content] )
        block.call( group )
      end
    end

    def add_action name, role, waiting = false
      @waiting = waiting
      @action  = Action.create(
        :name     => name,
        :role     => role,
        :payload  => parse_body,
        :waiting  => waiting?,
        :uuid     => uuid,
        :api_key  => environment[:api_key]
      )
      
      async_group do |group| 
        puts "!!!!!!!!!! #{group.inspect}"
        
        if waiting?
          EM::Timer.new(60) do
            action.response = [504, {"message" => "request_timeout"}.to_json] unless @action.nil?
          end
        else
          @action.send_to_waiters( group ) if @action
          
          @action.verify( group ) if @action
          if @action
            EM::Timer.new(group.latency + self.action.timeout) do
              action.verify( group, true ) if self.action != nil
          
              # action could be changed in function call above
              action.invalidate if self.action != nil
            end
          end
        end
      end
    end
    
    def success &block
      @success = block
    end
    
    def update
      @success.call( action ) if @success && @action
      @action = nil;
    end
    
    def grouped hash = nil, &block
      @grouped              = block
      @current_group_hash   = hash
      
      async_group { |group| update_grouped( group.client_infos ) }
      
      @peek_timer = EM::Timer.new(60) do
        async_group { |group| update_grouped( group.client_infos, true ) }
      end
    end
    
    def update_grouped group, forced = false
      # return if group == nil

      md5 = Digest::MD5.hexdigest( group.to_json )
      
      if (@current_group_hash != md5 && group.size > 0) || forced
        response = { :group_id => md5, :group => group }
        @grouped.call( response ) if @grouped
        
        @peek_timer.cancel if @peek_timer
      end
    end
  end
end
