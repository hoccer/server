require 'uri'

module Hoccer
  class Action < Hash

    attr_accessor :response

    def self.create hash
      case hash[:name]
      when 'one-to-one'
        OneToOne.new.merge!( hash )
      when 'one-to-many'
        OneToMany.new.merge!( hash )
      end
    end

    def uuid
      self[:uuid]
    end

    # client performing the action

    def client
      Client.find( self[:uuid] )
    end

    # when response is assigned a value terminate action
    # (@action = nil for client)

    def response=(response)
      @response = response
      client.update
    end

    # send payload to waiting clients

    def send_to_waiters group

      # if client is sender

      return if self[:role] == :receiver

      # get clients in the same group with same action type and waiting set to true

      clients   = group.clients_with_action( name )
      waiters    = clients.select { |c| c.action[:role] == :receiver && c.action[:waiting] }

      # set responses (terminates the waiting clients' actions)

      waiter_uuids = waiters.map { |w| w.uuid }
      logs "payload sent from client #{uuid} to waiting clients #{waiter_uuids.inspect}: #{self[:payload].inspect}" unless waiters.size == 0

      waiters.each do |w|
        w.action.response = [200, [ self[:payload] ] ]
      end

      on_success( [ self[:payload] ], [ client ] , waiters )

      # if payload was sent, ensure no timeout response is given to the sending client when no further receivers are found later

      @content_sent = true unless waiters.size == 0
    end

    # check for compatible senders/receivers
    # if successful, send content and terminate actions of participating clients
    # reevaluate = false : only send and terminate if the client's entire group is participating in the action

    def verify group, reevaluate = false

      # if there is no other client in group, terminate with timeout or success (if content has already been sent to waiting clients)

      if (group.size_without_waiters < 2)
        invalidate
      end

      # get all clients in group with same action type

      clients   = group.clients_with_action( name )

      sender    = clients.select { |c| c.action[:role] == :sender }
      receiver  = clients.select { |c| c.action[:role] == :receiver && !c.action[:waiting] }

      receiver_uuids = receiver.map { |r| r.uuid }
      sender_uuids = sender.map { |s| s.uuid }

      logs "verifying transaction of type #{name}. senders: #{sender_uuids.inspect}, receivers: #{receiver_uuids.inspect}"

      # return if no others are found

      return if clients.size < 2

      # check for conflict (numbers of senders and receivers incompatible with action type)

      if conflict? sender, receiver
        conflict clients

      # if the clients that participate in the action have been successfully identified
      # (compatible number of senders and receivers, if reevaluate=false all clients in group participating)

      elsif success? sender, receiver, group, reevaluate

        # send payload to all clients and terminate actions

        data = sender.map { |s| s.action[:payload] }

        logs "payload sent from client #{sender[0].uuid} to clients #{receiver_uuids.inspect}: #{data.inspect}"

        clients.each { |x| x.action.response = [200, data] }
        
        on_success( data, sender, receiver )
      end
    end

    # terminate with timeout or success (if content has already been sent to waiting clients)

    def invalidate
      if @content_sent
        self.response = [200, [ self[:payload] ] ]
      else
        logs "timeout for client #{uuid}"
        self.response = [204, {"message" => "timeout"}]
      end
    end

    # terminate actions with conflict response

    def conflict clients
      client_uuids = clients.map { |c| c.uuid }
      logs "conflict for clients #{client_uuids.inspect}"

      clients.each do |c|
        c.action.response = [409, {"message" => "conflict"}]
      end
    end
    
    # when data was successfully transferred

    def on_success payload, senders, receivers 
      
      # if content was a hoclet, send information about transfer
      
      if payload.first && payload.first["data"] && payload.first["data"][0] 
        data = payload.first["data"][0]
        return unless data["type"] == "text/x-hoclet"
        
        uri = URI.parse(data["content"])
    
        http = EM::Protocols::HttpClient.request(
	        :host => 'localhost',
	        :port => 9413,
          :verb => 'POST',
          :request => "#{uri.path}/transaction",
          :content => {
          :sender   => senders.first.uuid, 
          :receiver => receivers.first.uuid
          }.to_json
        )
      end
    end
    
    private
  end

  # action type one-to-one
  # one sender, one receiver
  # waiting for 3s (+latency) before timeout

  class OneToOne < Action
    def name
      "one-to-one"
    end

    def timeout
      3
    end

    def conflict? sender, receiver
      sender.size > 1 || receiver.size > 1
    end

    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size == 1 && (group.size == 2 || reevaluate)
    end
  end

  # action type one-to-many
  # one sender, one receiver
  # waiting for 5s (+latency) before timeout

  class OneToMany < Action
    def name
      "one-to-many"
    end

    def timeout
      5
    end

    def conflict? sender, receiver
      sender.size > 1
    end

    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size >= 1 && (sender.size + receiver.size == group.size || reevaluate)
    end
  end
end
