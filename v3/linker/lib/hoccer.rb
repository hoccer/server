require 'sinatra/reloader'
require 'action'
require 'group'
require 'client'
require 'helper'

# Pattern for common prefix of client requests.

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"

module Hoccer

  # Root of the application.
  #
  # This is where requests enter the linker.
  #

  class App < Sinatra::Base
    register Sinatra::Async

    configure(:development) do
      register Sinatra::Reloader
    end

    set :public, File.join(File.dirname(__FILE__), '..', '/public')

    # say hello when spoken to

    get "/" do
      "This is the Hoccer Linker in the #{HOCCER_ENV} environment."
    end

    # when receiving a client request of some kind, first find
    # or create the object representing the current client

    before %r{#{CLIENTS}/.*$} do |uuid|
      @current_client = Hoccer::Client.find_or_create( uuid )
      @current_client.update_connection self
      logs "request #{@current_client.uuid} #{request.request_method} #{request.path_info}"
    end

    # GET request to receive client info

    aget %r{#{CLIENTS}$} do |uuid|
      @current_client.info do |response|
        if response[:status] == 200
          logs "returning client info: #{response[:content].inspect}"
          body { response[:content] }
        else
          logs "returning client info failed: client #{uuid} not found}"
          status 404
          body { {:error => "Client with uuid #{uuid} was not found"}.to_json }
        end
      end
    end

    # PUT request to set environment data for client (location etc.)
    # returns hoccability

    aput %r{#{CLIENTS}/environment$} do |uuid|
      authorized_request do |account| # check valid api key / signature
        @current_client.update_environment do |response|
          if response[:status] == 200
            status 201
            content = JSON.parse( response[:content] )
            body { content["hoccability"].to_json }
          else
            logs "environment update for client #{uuid} failed. parser returned error: #{@current_client.error}"
            status 400
            body { {:error => @current_client.error}.to_json }
          end
        end

        # updating the world map for every environment update

        @current_client.update_worldmap
      end
    end

    # DELETE request to sign off current client

    adelete %r{#{CLIENTS}/environment$} do |uuid|
      @current_client.delete do |response|
        logs "client #{uuid} deleted. updated clients: #{response.inspect}"
        status 200
        body {"deleted"}
      end
    end

    # PUT request to share data with other clients
    # action_name can be one-to-one or one-to-many

    aput %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :sender )
      @current_client.success do |action|
        status action.response[0]
        body { action.response[1].to_json }
      end
    end

    # GET request to receive data from other clients
    # action_name can be one-to-one or one-to-many
    # optional parameter "waiting" to keep the connection open

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :receiver, !!params[:waiting] )
      @current_client.success do |action|
        status action.response[0]
        body { action.response[1].to_json }
      end
    end

    # GET request to receive information about the client's group

    aget %r{#{CLIENTS}/peek$} do |uuid|
      @current_client.grouped(params["group_id"]) do |group|
        logs "responding to peek from client #{uuid}: #{group}"
        status 200
        content_type "application/json"
        body { group.to_json }
      end
    end

    # GET request to receive the public key associated with a hash id

    aget %r{#{CLIENTS}/([a-fA-F0-9]{8,8})/publickey$} do |uuid, hashid|
      @current_client.publickey(hashid) do |response|
        logs "returning public key for hash #{hashid} to client #{uuid}"
        status 200
        content_type "text/plain"
        body { { :pubkey => response[:content]}.to_json}
      end
    end

    # javascript routes
    aget %r{#{CLIENTS}/environment.js$} do |uuid|
      authorized_request do
        method = params["method"].to_s
        if (method == "delete")
          @current_client.delete do |response|
            logs "client #{uuid} deleted. updated clients: #{response.inspect}"
            status 200
            body {"deleted"}
          end
        else
          environment = {
            :gps => {
              :latitude   => params["latitude"].to_f,
              :longitude  => params["longitude"].to_f,
              :accuracy   => params["accuracy"].to_f,
              :timestamp  => params["timestamp"].to_f
            },

            :api_key => params["api_key"],
            :client_name => params["client_name"],
          }

          unless params["bssids"].nil?
            environment[:wifi] = {
              :bssids    => params["bssids"],
              :timestamp => Time.now.to_i
            }
          end

          unless params["pubkey"].nil?
            environment[:pubkey] = params["pubkey"].tr(' ','+')
          end

          unless params["selected_clients"].nil?
            environment[:selected_clients] = params["selected_clients"]
          end

          em_put( "/clients/#{uuid}/environment", environment.to_json ) do |response|
            status 201
            headers "Access-Control-Allow-Origin" => "*"
            body { environment.to_json }
            puts "#{environment.to_json}"
          end
        end
      end
    end

    aget %r{#{CLIENTS}/action/send.js$} do |uuid|
      if params["payload"]
        content = params["payload"]
        content['data'] = content['data'].values
      end
      @current_client.body_content = content

      @current_client.add_action( params[:mode], :sender )
      @current_client.success do |action|
        headers "Access-Control-Allow-Origin" => "*"

        status action.response[0]
        body   { action.response[1].to_json }
      end
    end

    aget %r{#{CLIENTS}/action/receive.js$} do |uuid|
      @current_client.add_action( params[:mode], :receiver, true )
      @current_client.success do |action|
        headers "Access-Control-Allow-Origin" => "*"

        status action.response[0]
        body   { action.response[1].to_json }
      end
    end

    aget %r{#{CLIENTS}/action/peek.js$} do |uuid|
      @current_client.grouped(params[:group_id]) do |group|
        logs "responding to peek from client #{uuid}: #{group}"
        headers "Access-Control-Allow-Origin" => "*"
        status 200
        body { group.to_json }
      end
    end

    aget %r{#{CLIENTS}/([a-fA-F0-9]{8,8})/publickey.js$} do |uuid, hashid|
      @current_client.publickey(hashid) do |response|
	headers "Access-Control-Allow-Origin" => "*"
        puts "returning public key for hash #{hashid} to client #{uuid}"
        status 200
        content_type "text/plain"
        body {response[:content].to_json}
      end
    end

  end
end
