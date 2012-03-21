module Hoccer

  class Group

    # should be initialized with json data received from grouper

    def initialize response
      if response.is_a? Array
        @members = response
      else 
        @members = JSON.parse( response )
      end
    end

    # group latency
    # maximum of the latencies of group members, but at most 6s
    # default 3s (if no client latencies are known)

    def latency
      if 1 < @members.size && @members.any? { |x| x["latency"] }
        latencies = @members.map { |x| ( x["latency"] || 3000 ) }
        max_latency = latencies.max / 1000
        if max_latency > 6
          max_latency = 6
        end
      else
        max_latency = 3
      end

      max_latency
    end

    def size
      @members.size
    end

    # number of group members not trying to receive data with the waiting parameter set

    def size_without_waiters
      clients.inject(0) do |sum, element|
        sum += 1 unless element.waiting?
        sum
      end
    end

    # objects representing the group's member clients

    def clients
      Client.find_all_by_uuids( @members.map { |m| m['client_uuid'] } ) #rescue []
    end

    # clients in group currently attempting to perform an action of a given type (e.g. one-to-one)

    def clients_with_action name
      clients.select do |c|
        ( c.action != nil && c.action.name == name ) rescue false
      end
    end

    # get information about clients in group
    # client name, hash id for public key (if existing), id (uuid for self, hash returned by the grouper for other clients)
    # (part of answer to peek request)

    def client_infos uuid
      return [] if @members.is_a?(Hash)

      @members.map do |m|
        client = {:name => m["client_name"]}
        if m["pubkey_id"]
          client[:pubkey_id] = m["pubkey_id"]
        end
        if uuid == m["client_uuid"]
          client[:id] = m["client_uuid"] 
        else
          client[:id] = m["anonymized"] 
        end
        client
      end
    end
  end

end
