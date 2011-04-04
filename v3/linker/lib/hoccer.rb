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

    @@action_store  = ActionStore.new
    @@evaluators    = {}

    def initialize
      super
      @@evaluators['one-to-one']  = OneToOne.new @@action_store
      @@evaluators['one-to-many'] = OneToMany.new @@action_store
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
      
      @current_client.success do 
        
      end
      # 
      # @current_client.error do 
      # 
      # end
      
      # @@evaluators[action_name].add action
    end

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      @current_client.add_action( action_name, :receiver )
      
      @current_client.success do 
         request.status = action.response[0]
         request.body   = action.response[1]
      end
      
      # action = {
      #   :mode     => action_name,
      #   :type     => :receiver,
      #   :request  => self,
      #   :uuid     => uuid,
      #   :waiting  => ( params['waiting'] || false ),
      #   :api_key  => params["api_key"]
      # }
      # @@evaluators[action_name].add action
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

      puts params["payload"];
      if params["payload"]
        content = params["payload"]
        content['data'] = content['data'].values
      end

      puts content

      action  = {
        :mode     => params["mode"],
        :type     => :sender,
        :payload  => content,
        :request  => self,
        :uuid     => uuid,
        :jsonp_method => (params["jsonp"] || params["callback"]),
        :api_key  => params["api_key"]
      }

      headers "Access-Control-Allow-Origin" => "*"

      @@evaluators[params["mode"]].add action
    end

    aget %r{#{CLIENTS}/action/receive.js$} do |uuid|
      action = {
        :mode         => params["mode"],
        :type         => :receiver,
        :request      => self,
        :uuid         => uuid,
        :jsonp_method => (params["jsonp"] || params["callback"]),
        :waiting      => (params["waiting"] || false),
        :api_key      => params["api_key"]
      }

      headers "Access-Control-Allow-Origin" => "*"

      @@evaluators[params["mode"]].add action
    end

  end

end
