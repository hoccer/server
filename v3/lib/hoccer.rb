require 'client'

module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async

    post "/clients" do
      client = Client.create
      redirect "/clients/#{client.uuid}", 303
    end

    get %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      if client = Client.find( uuid )
        content_type :json
        body { {:uri => "/clients/#{client.uuid}"}.to_json }
      else
        halt 412
      end
    end

    aput %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      if client = Client.find( uuid )
        ahalt 200

        EM.next_tick do
          client.environment = JSON.parse( request.body.string )
          client.rebuild_groups
        end
      else
        halt 412
      end
    end

    post %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|
      if client = Client.find( uuid )
        payload = JSON.parse( params.keys.first )
        client.actions[action] = payload
        client.mode = :sender
        halt 303
      else
        halt 412
      end
    end

    aget %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|
      if client = Client.find( uuid )

        client.request = self

        if client.actions[action].nil?
          client.actions[action] = {}
        end

        EM::Timer.new(7) do
          client.all_in_group.each do |client|
            client.request.body { {"message" => "timeout"}.to_json }
            client.actions.delete( action )
          end
        end

        timer = EventMachine::PeriodicTimer.new(0.1) do
          clients   = client.all_in_group.select(&:sender?)
          receiver  = client.all_in_group.reject(&:sender?)

          if clients.size >= 1 && receiver.size >= 1
            timer.cancel
            client.all_in_group.each do |client|
              client.request.body { "success" }
            end
          end
        end

      else
        halt 412
      end

    end

  end

end
