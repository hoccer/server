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
        group = parse_group response[:content]

        if group.size < 2
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

    def conflict actions
      actions.each do |client|
        @action_store.conflict client[:uuid]
      end
    end

    def timeout
      2
    end

    private
    def parse_group json_string
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

    def timeout
      2
    end

    def verify group, reevaluate = false
      actions = @action_store.actions_in_group(group, "one-to-one")
      sender   = actions.select { |c| c[:type] == :sender }
      receiver = actions.select { |c| c[:type] == :receiver }
      
      puts "verifying #{actions.size} actions with #{sender.size} senders and #{receiver.size} receivers"

      if sender.size > 1 || receiver.size > 1
        conflict actions
      elsif sender.size == 1 && receiver.size == 1 && (group.size == 2 || reevaluate)
        data_list = sender.map { |s| s[:payload] }
        Logger.successful_actions actions

        actions.each do |client|
          @action_store.send client[:uuid], data_list
        end
      end
    end
  end

  class OneToMany < Event
    def timeout
      7
    end

    def verify group, reevaluate = false
      actions = @action_store.actions_in_group(group, "one-to-many")
      sender   = actions.select { |c| c[:type] == :sender }
      receiver = actions.select { |c| c[:type] == :receiver }

      if sender.size > 1
        actions.each do |client|
          @action_store.conflict client[:uuid]
        end
      elsif sender.size == 1 && receiver.size >= 1 && (sender.size + receiver.size == group.size || reevaluate)

        data_list = sender.map { |s| s[:payload] }
        Logger.successful_actions actions

        actions.each do |client|
          @action_store.send client[:uuid], data_list
        end
      end
    end
  end
end

