module Hoccer

  class Client

    attr_accessor :client_id, :request

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

  end

  class App < Sinatra::Base

    register Sinatra::Async

    @@client_pool = ClientPool.new

    def client_id
      rand(2**16)
    end

    aget "/hi" do
      @client = Client.new client_id, self
      @@client_pool.insert @client

      EM::Timer.new(7) do
        @@client_pool.clients[@client.client_id].request.body { "hello" }
        @@client_pool.remove @client
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
