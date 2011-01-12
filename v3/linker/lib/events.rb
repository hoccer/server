require 'helper'

module Hoccer
  
  class Event

    def initialize action_store
      @action_store = action_store
    end

    def add action, waiting = false
      uuid = action[:uuid]
      @action_store[uuid] = action

      em_get( "/clients/#{uuid}/group") do |response|
        group = group_from_json response[:content]

        if group.size < 2 && !waiting
          @action_store.invalidate uuid
        else
          verify group
        end
        
        EM::Timer.new(timeout) do
          if @action_store[uuid]
            verify group, true
            @action_store.invalidate(uuid) unless waiting
          end
        end
      end
    end
    
    def verify group, reevaluate = false
      actions = @action_store.actions_in_group(group, name)
      sender   = actions.select { |c| c[:type] == :sender }
      receiver = actions.select { |c| c[:type] == :receiver }
      
      puts "verifying group (#{group.size}) with #{actions.size} actions with #{sender.size} senders and #{receiver.size} receivers"

      if conflict? sender, receiver
        conflict actions
      elsif success? sender, receiver, group, reevaluate
        data_list = sender.map { |s| s[:payload] }
        Logger.successful_actions actions

        actions.each do |client|
          @action_store.send client[:uuid], data_list
        end
      end
    end
    
    def conflict actions
      actions.each do |client|
        @action_store.conflict client[:uuid]
      end
    end

    def timeout
      2
    end

    private
    def group_from_json json_string
      begin
        group = JSON.parse json_string
      rescue => e
        puts e
        group = {}
      end
      group
    end

  end

  class OneToOne < Event

    def name
      "one-to-one"
    end

    def timeout
      2
    end

    def conflict? sender, receiver
      sender.size > 1 || receiver.size > 1
    end
    
    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size == 1 && (group.size == 2 || reevaluate)
    end
  end

  class OneToMany < Event
    def name
      "one-to-many"
    end
    
    def timeout
      7
    end

    def conflict? sender, receiver
      sender.size > 1
    end
    
    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size >= 1 && (sender.size + receiver.size == group.size || reevaluate)
    end
    
  end
end

