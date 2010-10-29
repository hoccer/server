require 'sinatra/reloader' 
require 'logger'
require 'action_store'

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"

module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async
    
    configure(:development) do
      register Sinatra::Reloader
    end
    
    @@server        = "localhost"
    @@port          = 4567
    @@action_store  = ActionStore.new
    
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
            Logger.successful_actions clients
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
      payload       = JSON.parse( request.body.read )

      action= {
        :mode     => action_name,
        :type     => :sender,
        :payload  => payload,
        :request  => self,
        :uuid    => uuid
      }
      
      @@action_store.hold_action_for_seconds action, 2
      
      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        group = parse_group response[:content] 
        
        if group.size < 2
          @@action_store.invalidate uuid
        else          
          verify_group @@action_store.actions_in_group(group, action_name)
        end
      end
    end

    aget %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      action = { :mode => action_name, :type => :receiver, :request => self, :uuid => uuid }
      
      @@action_store.hold_action_for_seconds action, 2

      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        group = parse_group response[:content] 
        
        if group.size < 2
          @@action_store.invalidate uuid
        else          
          verify_group @@action_store.actions_in_group(group, action_name)
        end  
        
      end
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

end
