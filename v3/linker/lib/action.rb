module Hoccer
  class Action < Hash

    @@actions = {}
    
    attr_accessor :response

    def self.create hash
      case hash[:name]
      when 'one-to-one'
        @@actions[hash[:uuid]] = OneToOne.new.merge!( hash )
      when 'one-to-many'
        @@actions[hash[:uuid]] = OneToMany.new.merge!( hash )
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
      actions   = actions_in_group(group, name)
      
      puts "actions ++++++++"
      puts actions
      
      return if actions.size < 2
      
      sender    = actions.select { |c| c.action[:role] == :sender }
      receiver  = actions.select { |c| c.action[:role] == :receiver }
      waiter    = actions.select { |c| c.action[:waiting] }

      puts "verifying group (#{group.size}) with #{actions.size} actions with #{sender.size} senders and #{receiver.size} receivers"

      if !sender.empty? and !waiter.empty?        
        data_list = sender.map { |s| s.action[:payload] }
        
        sender.each { |x| x.action.response = [200, data_list] }
        waiter.each { |x| x.action.response = [200, data_list] }
      end

      # deliver( sender,  waiter )

      if conflict? sender, receiver
        conflict actions
      elsif success? sender, receiver, group, reevaluate
        deliver( sender, actions )
      # elsif delivered? sender, reevaluate
      else
        deliver( sender, sender )
      end

      # if sender.all? {|x| x.request}
      #   deliver( sender, sender )
      # end
    end

    def deliver sender, receivers

      receivers.each do |receiver|
        data_list = []

        sender.each do |s|
          # s[:sent_to] ||= []
          # unless s[:sent_to].include?( receiver[:uuid] )
          # s[:sent_to] << receiver[:uuid]
            data_list << s.action[:payload]
          # end
        end

        unless data_list.empty?
          send( data_list )
        end
      end
    end

    def hold_action_for_seconds action, seconds
      uuid = action[:uuid]
      self[uuid] = action

      EM::Timer.new(seconds) do
        invalidate uuid
      end
    end

    def invalidate
      send_no_content
      @@actions[self[:uuid]] = nil
    end

    # def send_timeout uuid
    #   action = self[uuid]
    #   unless action.nil? || action[:request].nil?
    #     action[:request].ahalt 504
    #   end
    #   self[uuid] = nil
    # end

    def conflict uuid
      self.response = [409, {"message" => "conflict"}]
    end

    def send content
        self.response = [200, content]
    end

    def actions_in_group group, mode
      clients = group.clients.select do |c|
        c.action && c.action.name == self.name
      end
    end

    private
    def send_no_content
      puts "timeout for #{uuid}"
      self.response = [204, {"message" => "timeout"}]
    end

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
