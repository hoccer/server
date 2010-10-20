require 'client'
require 'action'



module Hoccer
  # CLIENTS = "/clients/([A-Z0-9\-]{36,36})"
  CLIENTS = "/clients/(.+)"
  
  class App < Sinatra::Base
    register Sinatra::Async

    @@server        = "localhost"
    @@port          = 4567
    @@action_store  = {}
    @@requests      = {}
    
    def em_request path, method, content, &block
      http = EM::Protocols::HttpClient.request(
        :host => @@server,
        :port => @@port,
        :verb => method   ||= "GET",
        :request => path  ||= "/",
        :content => content
      )

      http.callback do |response|
        puts response[:status]
        puts response[:headers]
        block.call( response )
      end
    end

    def verify_group clients
      sender   = clients.select { |c| c[:mode] == :sender }
      receiver = clients.select { |c| c[:mode] == :receiver }

      if sender.size >= 1 && receiver.size >= 1
        clients.each do |client|
          if client.request
            puts "Y A Y"

            data_list = sender.map { |s| s[:payload] }

            client.request.body { data_list.to_json }
            client.request = nil
          end
        end
      end
    end

    aget %r{#{CLIENTS}$} do |uuid|
      em_request( "/clients/#{uuid}", nil, nil ) do |response|
        if response[:status] == 200
          body { response[:content] }
        else
          status 404
          body { {:error => "Not Found"}.to_json }
        end
      end
    end
    
    aput %r{/clients/(.+)/environment} do |uuid|
      em_request( "/clients/#{uuid}/environment", "PUT", request.body.read ) do |response|
        status 201
        body { "Created" }
      end
    end

    delete %r{#{CLIENTS}/environment} do |uuid|

    end

    apost %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      request_body  = request.body.read
      payload       = JSON.parse( request_body )

      em_request( "/clients/#{uuid}", nil, nil ) do |response|
        if response[:status] == 200
          @@action_store[uuid] = {
            :action   => action_name,
            :mode     => :sender,
            :payload  => payload
          }

          body { @@action_store.to_json }
        else
          status 404
          body { {:error => "Not Found"}.to_json }
        end
      end
    end

    aget %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      @@action_store[uuid] ||= { :action => action_name, :mode => :receiver }
      @@action_store[uuid][:request] = self

      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        r = JSON.parse(response[:content])
        clients = r.inject([]) do |result, environment|
          client = @@action_store[ environment["client_uuid"] ]
          result << client unless client.nil?
          result
        end

        EM::Timer.new(7) do
          clients.each do |client|
            if client[:request]
              client[:request].status 201
              client[:request].body { {"message" => "timeout"}.to_json }
            end
            client[:action]   = nil
            client[:request]  = nil
          end
        end

        verify_group clients
      end
    end

  end

end
