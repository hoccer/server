require 'ruby-debug'

module Hoccer
  class Client

    # XXX remove this once XXX below cleared
    UUID_PATTERN = /[a-zA-Z0-9\-]{36,36}/

    attr_accessor :environment,
                  :action,
                  :error,
                  :uuid,
                  :hoccability,
                  :waiting,
                  :body_content

    # class variable mapping uuids to client objects

    @@clients = {}

    def initialize uuid
      @uuid             = uuid

      @@clients[@uuid]  = self
    end

    # update client
    # called when receiving any request

    def update_connection connection
      # XXX why do we update the UUID here? this should never have an effect.
      @uuid             = connection.request.path_info.match(UUID_PATTERN)[0]
      @body_content     = nil
      @body_buffer      = connection.request.body.read
      @environment      = { :api_key => connection.params["api_key"] }
      @error            = nil
    end

    # parse json data (environment data or payload)

    def parse_body
      begin
        @body_content || JSON.parse( @body_buffer )
      rescue => e
        @error = e.message
        false
      end
    end

    # pass request for client info to grouper

    def info &block
      em_get( "/clients/#{uuid}" ) { |response| block.call( response ) }
    end
    
    # pass request for public key to grouper

    def publickey hashid, &block
      em_get( "/clients/#{uuid}/#{hashid}/publickey" ) { |response| block.call( response ) }
    end

    # return client belonging to uuid

    def self.find uuid
      @@clients[uuid]
    end

    # return array of clients belonging to array of uuids

    def self.find_all_by_uuids uuids
      uuids.inject([]) do |result, uuid|
        result << @@clients[uuid]
      end
    end

    # find or create the object representing the current client

    def self.find_or_create uuid
      @@clients[uuid] ||= Client.new( uuid )
    end

    # set environmente data for client

    def update_environment &block

      # get environment data from request body
      # if data could not be parsed, return with error

      parsed_environment = parse_body

      unless parsed_environment
         block.call( { :status => 400 } )
         return
      end

      @environment.merge!( parsed_environment )

      puts "environment update for client #{uuid}: #{environment.inspect}"

      # pass request to grouper
      
      em_put( "/clients/#{uuid}/environment", @environment.to_json ) do |response|
        block.call( response )
        begin
          content = JSON.parse( response[:content] )
        rescue
          content = { "group" => [] }
        end

        # for all clients in the same group (as returned by the grouper): update group info (if client is peeking)

        ids = content["group"].map { |info| info["client_uuid"] }

        puts "updated clients after environment update for client #{uuid}: #{ids.inspect}"

        Client.find_all_by_uuids( ids ).each do |client|
          group = Group.new(content['group'])
          client.update_grouped( group ) if client
        end
      end
    end

    # update the worldmap
    # called after every environment update

    def update_worldmap
      if data = (@environment["gps"] || @environment["network"])
        worldmap_request "PUT", "/hoc", data.to_json
      end
    end

    # log action in database
    # called when an action terminates

    def log_action action_name, api_key
      EM.next_tick do
        $db         ||= EM::Mongo::Connection.new.db( Hoccer.config["database"] )
        collection  = $db.collection('api_stats')
        doc = {
          :api_key    => api_key,
          :action     => action_name,
          :timestamp  => Time.now
        }
        collection.insert( doc )
      end
    end

    # sign off client

    def delete &block

      # get current group from grouper, then pass on delete request

      async_group do |group|
        em_delete("/clients/#{uuid}/delete") do |response|
          begin
            content = JSON.parse(response[:content])
          rescue
            puts "could not parse grouper response to delete request: #{response[:content]}"
            content = []
          end
          block.call(content)

          # for all clients in the same group: update group info (if client is peeking)

          changed_clients = Client.find_all_by_uuids(content)
          changed_clients.each do |client|
            client.async_group do |new_group|
              client.update_grouped( new_group )
            end
          end
        end
      end
    end

    # whether waiting has been set for the current request

    def waiting?
      @waiting
    end

    # get the client's current group from the grouper before executing the block

    def async_group &block
      em_get( "/clients/#{uuid}/group") do |response|
        group = Group.new( response[:content] )
        block.call( group )
      end
    end

    # get the client's current selected group from the grouper before executing the block

    def async_selected_group &block
      em_get("/clients/#{uuid}/selected_group") do |response|
        group = Group.new( response[:content] )
        block.call( group )
      end
    end

    # perform action
    # name: one-to-one or one-to-many
    # role: sender or receiver

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

      # get the client's current selected group from the grouper

      async_selected_group do |group|

        # if payload could not be parsed, return with error

        encoded_error = {:error => self.error}.to_json
        if @action
          @action.response = [400, encoded_error] unless @action[:payload] || @action[:role] == :receiver
        end

        # if waiting is set, wait 60s for another client to send data (which terminates the action)

        if waiting?
          EM::Timer.new(60) do
            @action.response = [504, {"message" => "request_timeout"}.to_json] unless @action.nil?
            puts "timeout for waiting client #{uuid}" unless @action.nil?
          end
        else

          # otherwise, first send payload to waiting clients in group if role is sender

          @action.send_to_waiters( group ) if @action

          # try to find compatible senders/receivers
          # if successful and the client's entire group is participating in the action, send content and terminate

          @action.verify( group ) if @action

          # if the action was not terminated, wait for timespan dependent on latency and action type and try again

          if @action
            EM::Timer.new(group.latency + self.action.timeout) do

              # find compatible senders/receivers
              # if successful, send content and terminate

              @action.verify( group, true ) if self.action != nil

              # if action was again not terminated, quit (timeout or sent only to waiters)

              @action.invalidate if self.action != nil
            end
          end
        end
      end
    end

    def success &block
      @success = block
    end

    # terminate the client's current action
    # called when the action's response is set

    def update
      unless @action.nil?
        log_action( action.name, @environment[:api_key] )

        @success.call( action ) if @success && @action
        @action = nil;
      end
    end

    # get information about current group (peek request)

    def grouped hash = nil, &block
      @grouped              = block
      @current_group_hash   = hash

      # get current group from grouper and set response (unless the group hash is unchanged)

      async_group { |group| update_grouped( group ) }

      # wait for another client to update the group with an environment update or by signing off
      # if that did not happen after 60s, get group info and set response even if group hash is unchanged

      @peek_timer = EM::Timer.new(60) do
        async_group { |group| update_grouped( group, true ) }
      end
    end

    # update group info for client
    # (set response to / terminate peek request)
    # called when the client peeks or a client in the same group updates its environment / signs off

    def update_grouped group, forced = false

      # get sorted list of clients in group and calculate hash
      
      group_array = group.client_infos( uuid )
      sorted_group = group_array.sort { |m,n| m[:id] <=> n[:id] }

      md5 = Digest::MD5.hexdigest( sorted_group.to_json )

      # if group has changed or the method is called with the forced parameter

      puts "forced group update for client #{uuid} after 60s" if forced

      if (@current_group_hash != md5 && group.size > 0) || forced

        # set response for peek request

        response = {
          :group_id => md5,
          :group => sorted_group
        }

        @grouped.call( response ) if @grouped

        # if client was peeking, stop
        # (if this method was called by another client's environment update or signing off)

        @peek_timer.cancel if @peek_timer
      end
    end
  end
end
