module Hoccer

  class Group

    def initialize response
      if response.is_a? Array
        @members = response
      else 
        @members = JSON.parse( response )
      end
    end

    def latency
      if 1 < @members.size && @members.any? { |x| x["latency"] }
        latencies = @members.map { |x| ( x["latency"] || 3 ) }
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

    def size_without_waiters
      clients.inject(0) do |sum, element|
        sum += 1 unless element.waiting?
        sum
      end
    end

    def clients
      Client.find_all_by_uuids( @members.map { |m| m['client_uuid'] } ) #rescue []
    end

    def clients_with_action name
      clients.select do |c|
        ( c.action != nil && c.action.name == name ) rescue false
      end
    end

    def client_infos uuid
      return [] if @members.is_a?(Hash)

      @members.map do |m|
        client = {:name => m["client_name"]}
        if m["public_key_hash"]
          client[:pubkey] = m["public_key_hash"]
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
