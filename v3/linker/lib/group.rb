module Hoccer

  class Group

    def initialize response
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

    def client_infos
      return [] if @members.is_a?(Hash)

      @members.map do |m|
        { :id => m["client_uuid"], :name => m["client_name"] }
      end
    end
  end

end
