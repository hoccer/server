require 'client'

module Hoccer

  class App < Sinatra::Base
    set :environment, :test

    register Sinatra::Async

    aget "/high" do
      content_type :json
      body { {:message => "hello"}.to_json }
    end

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
          client.environment = JSON.parse( params["json"] )
        end
      else
        halt 412
      end
    end

    #aget "/clients/:uuid/actions/:action" do |uuid, action|
    #  client = Client.new uuid, self
    #  @@client_pool.insert @client

    #  EM::Timer.new(7) do
    #    @@client_pool.clients[client.client_id].request.body { "hello" }
    #    @@client_pool.remove client
    #  end

    #  timer = EventMachine::PeriodicTimer.new(0.1) do
    #    if 1 < @@client_pool.clients.size
    #      timer.cancel
    #      @@client_pool.clients.values.each do |client|
    #        client.request.body { @@client_pool.clients.size }
    #      end
    #    end
    #  end

    #end

  end

end
