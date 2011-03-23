module Hoccer
  class Action < Hash

    @@actions = {}

    def initialize hash = {}
      case hash[:name]
      when 'one-to-one'
        @@actions[hash[:uuid]] = OneToOne.new( hash )
      when 'one-to-many'
        @@actions[hash[:uuid]] = OneToMany.new( hash )
      else
        super.merge!( hash )
      end
    end

    def hold_action_for_seconds action, seconds
      uuid = action[:uuid]
      self[uuid] = action

      EM::Timer.new(seconds) do
        invalidate uuid
      end
    end

    def invalidate uuid
      action = self[uuid]
      send_no_content( action ) unless action.nil?
      self[uuid] = nil
    end

    def send_timeout uuid
      action = self[uuid]
      unless action.nil? || action[:request].nil?
        action[:request].ahalt 504
      end
      self[uuid] = nil
    end

    def conflict uuid
      action = self[uuid]
      if action && action[:request]
        if (jsonp = action[:jsonp_method])
          action[:request].status 200
          action[:request].body { "#{jsonp}(#{ {"message" => "conflict"}.to_json })" }
        else
          action[:request].status 409
          action[:request].body { {"message" => "conflict"}.to_json }
        end
      end
      self[uuid] = nil
    end

    def send uuid, content
      action      = self[uuid]
      self[uuid]  = nil

      if action && action[:request]
        action[:request].status 200
        if (jsonp = action[:jsonp_method])
          action[:request].body { "#{jsonp}(#{content.to_json})" }
        else
          action[:request].body content.to_json
        end
      end
    end

    def actions_in_group group, mode
      actions = group.inject([]) do |result, environment|
        action = self[ environment["client_uuid"] ] rescue nil
        result << action unless action.nil?
        result
      end

      actions.select {|action| action[:mode] == mode}
    end

    private
    def send_no_content action
      puts "timeout for #{action[:uuid]}"

      if action && action[:request]
        request = action[:request]
        if (jsonp = action[:jsonp_method])
          request.status 200
          action[:request].body { "#{jsonp}(#{ {"message" => "timeout"}.to_json})" }
        else
          request.status 204
          request.body { {"message" => "timeout"}.to_json }
        end

      end


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
