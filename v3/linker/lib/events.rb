require 'helper'

module Hoccer
  class Group < Hash
    def self.from_json json_string
        begin
          group = JSON.parse json_string
        rescue => e
          puts e
          group = {}
        end
        group
      end
  end


  class Event
    def initialize action_store
      @action_store = action_store
    end

    def add action
      uuid = action[:uuid]
      @action_store[uuid] = action

      em_get( "/clients/#{uuid}/group") do |response|
        group = Group.from_json response[:content]

        if 1 < group.size && group.any? { |x| x["latency"] }
          latencies = group.map { |x| ( x["latency"] || 1 ) }
          max_latency = latencies.max / 1000
          if max_latency > 4
            max_latency = 4
          end
        else
          max_latency = 1
        end

        if group.size < 2 && !action[:waiting]
          @action_store.invalidate uuid
        else
          verify group
        end


        if action[:waiting]
          EM::Timer.new(60) do
            @action_store.send_timeout(uuid)
          end
        else
          EM::Timer.new(max_latency + timeout) do
            if @action_store[uuid]
              verify group, true
              @action_store.invalidate(uuid)
            end
          end
        end
      end
    end

    def verify group, reevaluate = false
      actions = @action_store.actions_in_group(group, name)
      sender   = actions.select { |c| c[:type] == :sender }
      receiver = actions.select { |c| c[:type] == :receiver }

      puts "verifying group (#{group.size}) with #{actions.size} actions with #{sender.size} senders and #{receiver.size} receivers"

      waiter = actions.select {|a| a[:waiting]}

      if 0 < waiter.size
        data_list = sender.map { |s| s[:payload] }

        unless data_list.empty?
          waiter.each do |waiter|
            @action_store.send waiter[:uuid], data_list
          end
        end

        sender.each {|s| @action_store.send( s[:uuid], data_list ) }
      end

      if conflict? sender, receiver
        conflict actions
      elsif success? sender, receiver, group, reevaluate
        data_list = sender.map { |s| s[:payload] }

        actions.each do |client|
          @action_store.send( client[:uuid], data_list )
          action = sender.first
          log_action( action[:mode], action[:api_key] ) if client[:type] == :receiver
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
  end

  class OneToOne < Event

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

  class OneToMany < Event
    def name
      "one-to-many"
    end

    def timeout
      4
    end

    def conflict? sender, receiver
      false
      #sender.size > 1
    end

    def success? sender, receiver, group, reevaluate
      sender.size == 1 && receiver.size >= 1 && (sender.size + receiver.size == group.size || reevaluate)
    end

  end
end

