require 'client'

module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async

    post "/clients" do
      puts "Generate UUID"
      client = Client.create
      redirect "/clients/#{client.uuid}", 303
    end

    get %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      puts "Check self reference"
      if client = Client.find( uuid )
        content_type :json
        body { {:uri => "/clients/#{client.uuid}"}.to_json }
      else
        halt 410
      end
    end

    aput %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      puts "Update Environment"
      request_body = request.body.read
      begin
        environment = JSON.parse( request_body )
        puts "|||||| #{environment.inspect}"
      rescue JSON::ParserError => e
        content_type :json
        body { {:error => "#{e.class} #{e.message}"}.to_json }
        halt 410
      end

      if !environment.empty? && client = Client.find( uuid )
        ahalt 200
        EM.next_tick do
          client.environment = environment
          client.rebuild_groups

        end
      else
        halt 412
      end
    end

    post %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|
      puts "Share action"
      if client = Client.find( uuid )
        payload = JSON.parse( request.body.read )
        client.actions[action] = payload
        client.mode = :sender
        redirect "/clients/#{client.uuid}/action/#{action}", 303
      else
        halt 412
      end
    end

    aget %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|
      puts "Action Info"
      if client = Client.find( uuid )
        puts ">>>>>>>>>>>>> #{client.all_in_group.size}"
        if client.all_in_group.size < 2
          puts "204"
          ahalt 204
        end

        client.request = self

        if client.actions[action].nil?
          client.actions[action] = {}
          client.mode = :receiver
        end

        EM::Timer.new(7) do
          client.all_in_group.each do |client|
            if client.request
              client.request.body { {"message" => "timeout"}.to_json }
            end
            client.actions.delete( action )
          end
        end

        timer = EventMachine::PeriodicTimer.new(0.1) do
          clients   = client.all_in_group.select(&:sender?)
          receiver  = client.all_in_group.select(&:receiver?)

          puts clients.map(&:uuid)
          puts receiver.map(&:uuid)

          if clients.size >= 1 && receiver.size >= 1
            timer.cancel
            client.all_in_group.each do |client|
              if client.request
                puts "Y A Y"
                client.request.body { "success" }
                client.request = nil
              end
            end
          end
        end

      else
        halt 412
      end

    end

  end

end
