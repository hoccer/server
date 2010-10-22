require 'sinatra/reloader' 

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"

module Hoccer
  # CLIENTS = "/clients/(.+)"
  
  class App < Sinatra::Base
    register Sinatra::Async
    
    configure(:development) do
      register Sinatra::Reloader
    end
    
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
      
      puts "sender   #{sender.count}"
      puts "receiver #{receiver.count}"
      
      if sender.size >= 1 && receiver.size >= 1
        clients.each do |client|
          if client[:request]
            data_list = sender.map { |s| s[:payload] }

            client[:request].body { data_list.to_json }
            client[:request] = nil
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
          body { {:error => "Client with uuid #{uuid} was not found"}.to_json }
        end
      end
    end
    
    aput %r{#{CLIENTS}/environment} do |uuid|
      request_body = request.body.read
      puts "put body: #{request_body}"
      em_request( "/clients/#{uuid}/environment", "PUT", request_body ) do |response|
        status 201
        body { "Created" }
      end
    end

    adelete %r{#{CLIENTS}/environment} do |uuid|
      em_request("/clients/#{uuid}/delete", "DELETE", nil) do |response|
        status 200
        body {"deleted"}
      end
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
          
          em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
            r = JSON.parse(response[:content])
            clients = r.inject([]) do |result, environment|
              client = @@action_store[ environment["client_uuid"] ]
              result << client unless client.nil?
              result
            end

            verify_group clients
            ahalt 302, {"Location" => "http://#{env["HTTP_HOST"]}/clients/#{uuid}/action/#{action_name}"}, []
          end
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
        group = JSON.parse(response[:content])
        clients = group.inject([]) do |result, environment|
          client = @@action_store[ environment["client_uuid"] ]
          result << client unless client.nil?
          result
        end
        
        if group.size < 2
          send_no_content self
        else
          EM::Timer.new(7) do
            clients.each do |client|
              send_no_content client[:request]

              client[:action]   = nil
              client[:request]  = nil
            end
          end
          verify_group clients
        end
      end
    end 
    
    private 
    def send_no_content request 
      if request
        request.status 204
        request.body { {"message" => "timeout"}.to_json }
      end
    end
    
     
  end

end
