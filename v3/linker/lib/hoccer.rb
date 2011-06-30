require 'sinatra/reloader'
require 'action'
require 'group'
require 'client'
require 'helper'

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"

module Hoccer
  class App < Sinatra::Base
    register Sinatra::Async

    configure(:development) do
      register Sinatra::Reloader
    end

    set :public, File.join(File.dirname(__FILE__), '..', '/public')

    before do
      @current_client = Hoccer::Client.find_or_create( self )
      @current_client.update_connection self
    end

    aget %r{#{CLIENTS}$} do |uuid|
      @current_client.info do |response|
        if response[:status] == 200
          body { response[:content] }
        else
          status 404
          body { {:error => "Client with uuid #{uuid} was not found"}.to_json }
        end
      end
    end

    aput %r{#{CLIENTS}/environment$} do |uuid|
      authorized_request do |account|
        @current_client.update_environment do |response|
          if response[:status] == 200
            status 201
            content = JSON.parse( response[:content] )
            body { content["hoccability"].to_json }
          else
            status 400
            body { {:error => @current_client.error}.to_json }
          end
        end

        @current_client.update_worldmap
      end
    end

    adelete %r{#{CLIENTS}/environment$} do |uuid|
      @current_client.delete do |response|
        puts "deleted #{response.inspect}"
        status 200
        body {"deleted"}
      end
    end

    aput %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :sender )
      @current_client.success do |action|
        status action.response[0]
        body { action.response[1].to_json }
      end
    end

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :receiver, !!params[:waiting] )
      @current_client.success do |action|
        status action.response[0]
        body { action.response[1].to_json }
      end
    end

    aget %r{#{CLIENTS}/peek$} do |uuid|
      @current_client.grouped(params["group_id"]) do |group|
        puts "peek #{group}"
	      status 200
        content_type "application/json"
        body { group.to_json }

        # @current_client.grouped nil
      end
    end
    
    aget %r{#{CLIENTS}/([a-eA-E0-9]{40,40})/publickey$} do |uuid, hashid|
      @current_client.publickey(hashid) do |publickey|
        status 200
        content_type "text/plain"
        body {publickey} 
      end
    end

    # javascript routes
    aget %r{#{CLIENTS}/environment.js$} do |uuid|
      authorized_request do
        method = params["method"].to_s
        if (method == "delete")  
	  @current_client.delete do |response|
            puts "deleted #{response.inspect}"
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

            :wifi => {
              :bssids    => params["bssids"],
              :timestamp => Time.now.to_i
            },
            :api_key => params["api_key"],
            :client_name => params["client_name"],
    	    :selected_clients => params["selected_clients"]
	  }
        
	  em_put( "/clients/#{uuid}/environment", environment.to_json ) do |response|
            status 201
            headers "Access-Control-Allow-Origin" => "*"
            body { environment.to_json }
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
        headers "Access-Control-Allow-Origin" => "*"
	      status 200
        
        body { group.to_json }
        # @current_client.grouped nil
      end
    end

  end
end
