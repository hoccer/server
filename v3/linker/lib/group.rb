module Hoccer

  class Group

    def initialize response
      puts response
      @members = JSON.parse( response )
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
    end

    def size
      @members.size
    end

    def clients
      Client.find_all_by_uuids( @members.map { |m| m['client_uuid'] } )
    end

    def clients_with_action name
      clients_with_action = clients.select do |c|
        c.action != nil && c.action.name == name
      end
    end

  end

end
