require 'client'
require 'action'

module Hoccer

  def self.db
    @@db ||= EM::Mongo::Connection.new.db('hoccer_v3')
  end

  class App < Sinatra::Base
    register Sinatra::Async

    def action_info_path action
      [
        "",
        "clients",
        "#{action[:client_uuid]}",
        "action",
        "#{action[:name]}",
        "#{action[:uuid]}"
      ].join("/")
    end

    apost "/clients" do
      client = Client.create
      redirect "/clients/#{client.uuid}", 303
    end

    aget %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      Client.first( :uuid => uuid ) do |client|
        if client
          content_type :json
          body { {:uri => "/clients/#{client.uuid}"}.to_json }
        else
          halt 410
        end
      end
    end

    aput %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      request_body = request.body.read
      begin
        environment = JSON.parse( request_body )
      rescue JSON::ParserError => e
        content_type :json
        body { {:error => "#{e.class} #{e.message}"}.to_json }
        ahalt 410
      end

      EM.next_tick do
        Client.first( :uuid => uuid ) do |client|
          if client && !environment.empty?
            client.environment = environment
            client.save
            ahalt 200
          else
            ahalt 412
          end
        end
      end
    end

    adelete %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      EM.next_tick do
        Client.first( :uuid => uuid ) do |client|
          if client
            client.environment = {}
            client.save
            ahalt 200
          else
            ahalt 412
          end
        end
      end
    end

    apost %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action_name|
      EM.next_tick do
        Client.first( :uuid => uuid ) do |client|
          if client
            payload = JSON.parse( request.body.read )
            action  = (client.actions[action_name] = { :payload => payload })

            client.mode = :sender
            redirect action_info_path( action ), 303
          else
            ahalt 412
          end
        end
      end
    end

    aget %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|
      if client = Client.find( uuid )
        if client.all_in_group.size < 2
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
              client.request.status 204
              client.request.body { {"message" => "timeout"}.to_json }
            end
            client.actions.delete( action )
          end
        end

        client.verify_group( action )

      else
        halt 412
      end

    end

  end

end
