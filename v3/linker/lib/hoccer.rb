require 'client'
require 'action'

module Hoccer

  def self.db
    @@db ||= EM::Mongo::Connection.new.db('hoccer_v3')
  end

  class App < Sinatra::Base
    register Sinatra::Async

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
            client.update_environment( environment )
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
            client.update_action( action_name, payload )

            ahalt 303, {'Location' => "/clients/#{uuid}/action/#{action_name}"}, ""
          else
            ahalt 412
          end
        end
      end
    end

    aget %r{/clients/([a-f0-9]{32,32})/action/(\w+)} do |uuid, action|

      Client.first( :uuid => uuid ) do |requesting_client|
        if requesting_client

          if requesting_client.action.nil?
            requesting_client.update_action action
          end

          requesting_client.request = self

          EM::Timer.new(7) do
            client.each_in_group do |client|
              if client.request
                client.request.status 204
                client.request.body { {"message" => "timeout"}.to_json }
                client.request = nil
              end
              #client.actions.delete( action )
            end
            ahalt 204
          end

          Client.collection.find(
            :group_id => requesting_client.group_id,
            :action   => requesting_client.action
          ) do |res|
            clients = res.map{ |r| Client.new( r ) }
            sender    = clients.select { |c| c.mode == :sender }
            receiver  = clients.select { |c| c.mode != :sender }

            if 0 < sender.size && 0 < receiver.size
              Client.requests_for_clients(clients).each do |request|
                request.status 200
                request.body { sender.map(&:payload).to_json }
              end
            else
              Client.requests_for_clients(clients).each do |request|
                request.status 204
                request.body { }
              end
            end
          end
        else
          ahalt 412
        end

      end
    end

  end

end
