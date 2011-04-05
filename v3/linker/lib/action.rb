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

    def client
      Client.find( self[:uuid] )
    end
    
    def response=(response)
      @response = response
      client.update
    end
    
    def verify group, reevaluate = false
      if (group.size < 2) 
        invalidate
      end
      
      clients   = group.clients_with_action( name )
      
      sender    = clients.select { |c| c.action[:role] == :sender }
      receiver  = clients.select { |c| c.action[:role] == :receiver }

      puts "verifying group (#{group.size}) with #{clients.size} actions with #{sender.size} senders and #{receiver.size} receivers"

      return if clients.size < 2
      
      if conflict? sender, receiver
        conflict clients
      elsif success? sender, receiver, group, reevaluate
        data = sender.map { |s| s.action[:payload] }
        
        clients.each { |x| x.action.response = [200, data] }
      end
    end

    def invalidate
      puts "timeout for #{uuid}"
      self.response = [204, {"message" => "timeout"}]
    end

    def conflict clients
      clients.each do |c|
        c.action.response = [409, {"message" => "conflict"}]
      end
    end

    private
  end

  class OneToOne < Action
    def name
      "one-to-one"
    end

    def timeout
      1.2
    end

    def conflict? sender, receiver
      sender.size > 1 || receiver.size > 1
    end

    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size == 1 && (group.size == 2 || reevaluate)
    end
  end

  class OneToMany < Action
    def name
      "one-to-many"
    end

    def timeout
      4
    end

    def conflict? sender, receiver
      sender.size > 1
    end

    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size >= 1 && (sender.size + receiver.size == group.size || reevaluate)
    end

  end

end
