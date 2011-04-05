require 'sinatra/reloader'
require 'action_store'
require 'action'
require 'group'
require 'events'
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
      @current_client = Hoccer::Client.new( self )
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
            body { response[:content] }
          else
            status 400
            body { {:error => @current_client.error}.to_json }
          end
        end

        @current_client.update_worldmap
      end
    end

    adelete %r{#{CLIENTS}/environment$} do |uuid|
      em_delete("/clients/#{uuid}/delete") do |response|
        status 200
        body {"deleted"}
      end
    end

    aput %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :sender )
      @current_client.success do |action|
        status action.response[0]
        body   action.response[1].to_json
      end
    end

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :receiver )
      @current_client.success do |action| 
         status action.response[0]
         body   action.response[1].to_json
      end
    end

    # javascript routes
    aget %r{#{CLIENTS}/environment.js$} do |uuid|
      authorized_request do
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
          :api_key => params["api_key"]
        }

        puts "put body #{environment}"
        em_put( "/clients/#{uuid}/environment", environment.to_json ) do |response|
          status 201
          headers "Access-Control-Allow-Origin" => "*"
          body { environment.to_json }
        end
      end
    end

    aget %r{#{CLIENTS}/action/send.js$} do |uuid|
      if params["payload"]
        content = params["payload"]
        content['data'] = content['data'].values
      end
      headers "Access-Control-Allow-Origin" => "*"
      
      @current_client.body_buffer = content
      
      @current_client.add_action( action_name, :receiver )
      @current_client.success do |action| 
        status action.response[0]
        body   { "#{jsonp}(#{action.response[1].to_json})" }
      end
    end

    aget %r{#{CLIENTS}/action/receive.js$} do |uuid|
      headers "Access-Control-Allow-Origin" => "*"
      
      @current_client.add_action( action_name, :receiver )
      @current_client.success do |action|
        status action.response[0]
        body   { "#{jsonp}(#{action.response[1].to_json})" }
      end
    end
    
    private
    
    def jsonp
      params[:jsonp] || params[:content]
    end
  end

end
