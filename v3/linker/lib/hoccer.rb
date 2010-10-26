require 'sinatra/reloader' 
require 'logger'

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
        block.call( response )
      end
    end

    def verify_group clients
      sender   = clients.select { |c| c[:type] == :sender }
      receiver = clients.select { |c| c[:type] == :receiver }
      
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

    aput %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      request_body  = request.body.read
      payload       = JSON.parse( request_body )

      @@action_store[uuid] = {
        :mode   => action_name,
        :type     => :sender,
        :payload  => payload,
        :request  => self
      }
      
      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        begin
          group = JSON.parse(response[:content]) 
        rescue => e
          puts e
          group = {}
        end  
        actions = actions_in group
        actions_with_mode = actions.select {|action| action[:mode] == action_name}

        if group.size < 2
          send_no_content self
        else
          timeout_action_after_delay uuid, 2
          
          verify_group actions_with_mode
        end
      end
    end

    aget %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      @@action_store[uuid] = { :mode => action_name, :type => :receiver, :request => self }

      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        begin
          group = JSON.parse(response[:content])
        rescue => e
          puts e
          group = {}
        end          
        actions = actions_in group
        actions_with_mode = actions.select {|action| action[:mode] == action_name}
      
        if group.size < 2
          send_no_content self
        else
          timeout_action_after_delay uuid, 2
          
          verify_group actions_with_mode
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
    
    def actions_in group 
      actions = group.inject([]) do |result, environment|
        action = @@action_store[ environment["client_uuid"] ]
        result << action unless action.nil?
        result
      end
      actions
    end
    
    def timeout_action_after_delay uuid, seconds 
      EM::Timer.new(seconds) do
        action = @@action_store[uuid]
        Logger.failed_action uuid, action
        
        send_no_content action[:request]
        action[:mode]   = nil
        action[:request]  = nil
      end
    end
    
    
  end

end
