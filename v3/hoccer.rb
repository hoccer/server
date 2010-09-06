require 'uuid'
require 'ruby-debug'

module Hoccer

  class Client

    attr_accessor :client_id, :request, :environment

    def initialize client_id, request
      @client_id = client_id
      @request   = request
    end

  end

  class ClientPool

    def initialize
      @pool = {}
    end

    def insert client
      @pool[client.client_id] = client
    end

    def remove client
      @pool.delete client.client_id
    end

    def clients
      @pool
    end

    def add_user
      uuid = UUID.generate(:compact)
      @pool[uuid] = Client.new uuid, nil
    end

  end

  class App < Sinatra::Base

    register Sinatra::Async

    @@client_pool = ClientPool.new

    def pool
      @@client_pool.clients
    end

    def client_pool
      @@client_pool
    end

    aget "/high" do
      body { "hello" }

    end

    post "/clients" do
      client = client_pool.add_user
      redirect "/clients/#{client.client_id}", 303
    end

    get %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      if pool[uuid]
        body { "yay" }
      else
        halt 412
      end
    end

    aget "/xxxx" do
      #client = @@client_pool.clients[uuid]
      #client.environment = params.keys.first
      body { "hello" }
    end

    aget "/clients/:uuid/actions/:action" do |uuid, action|
      client = Client.new uuid, self
      @@client_pool.insert @client

      EM::Timer.new(7) do
        @@client_pool.clients[client.client_id].request.body { "hello" }
        @@client_pool.remove client
      end

      timer = EventMachine::PeriodicTimer.new(0.1) do
        if 1 < @@client_pool.clients.size
          timer.cancel
          @@client_pool.clients.values.each do |client|
            client.request.body { @@client_pool.clients.size }
          end
        end
      end

    end

  end

end
