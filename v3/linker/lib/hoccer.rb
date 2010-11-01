require 'sinatra/reloader' 
require 'logger'
require 'action_store'

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"
  
SERVER        = "localhost"
PORT          = 4567

def em_request path, method, content, &block
  http = EM::Protocols::HttpClient.request(
    :host => SERVER,
    :port => PORT,
    :verb => method   ||= "GET",
    :request => path  ||= "/",
    :content => content
  )

  http.callback do |response|
    block.call( response )
  end
end
 
module Hoccer
  
  class OneToOne 
    def initialize action_store
      @action_store = action_store
    end

    def add action
      uuid = action[:uuid]
      @action_store[uuid] = action
      
      em_request( "/clients/#{uuid}/group", nil, nil ) do |response|
        group = parse_group response[:content] 
        
        if group.size < 2
          @action_store.invalidate action[:uuid]
        else          
          verify group  
        end
        
        EM::Timer.new(2) do
          if @action_store[uuid]
            verify group, true
            @action_store.invalidate uuid
          end
        end
        
      end
    end
       
    def verify group, reevaluate = false
      actions = @action_store.actions_in_group(group, "one-to-one")
      sender   = actions.select { |c| c[:type] == :sender }
      receiver = actions.select { |c| c[:type] == :receiver }
      
      puts "sender   #{sender.count}"
      puts "receiver #{receiver.count}"
      
      if sender.size > 1 || receiver.size > 1
        actions.each do |client|
          @action_store.conflict client[:uuid]
        end
      elsif sender.size == 1 && receiver.size == 1 && (group.size == 2 || reevaluate)
        data_list = sender.map { |s| s[:payload] }
        Logger.successful_actions actions        
        
        actions.each do |client|
          @action_store.send client[:uuid], data_list
        end
      end
    end

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
  
  
  class App < Sinatra::Base
    register Sinatra::Async
    
    configure(:development) do
      register Sinatra::Reloader
    end
    
    @@action_store  = ActionStore.new
    @@evaluators    = {}
     
    def initialize 
       super
       @@evaluators['one-to-one'] = OneToOne.new @@action_store
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

      action = { 
        :mode     => action_name,
        :type     => :sender,
        :payload  => payload,
        :request  => self,
        :uuid    => uuid
      }
      
      @@evaluators['one-to-one'].add action
    end

    aget %r{#{CLIENTS}/action/([\w-]+)} do |uuid, action_name|
      action = { :mode => action_name, :type => :receiver, :request => self, :uuid => uuid }
      
      @@evaluators['one-to-one'].add action
    end 
  end

end
