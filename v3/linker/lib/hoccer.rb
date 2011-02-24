require 'sinatra/reloader'
require 'action_store'
require 'events'
require 'helper'

CLIENTS = "/clients/([a-zA-Z0-9\-]{36,36})"

module Hoccer
  class App < Sinatra::Base
    register Sinatra::Async

    configure(:development) do
      register Sinatra::Reloader
    end

    helpers do
      def logger
        MuninLogger
      end
    end

    before do
      EM::Timer.new(60) do
        ahalt 504
      end
    end

    set :public, File.join(File.dirname(__FILE__), '..', '/public')

    @@action_store  = ActionStore.new
    @@evaluators    = {}

    def initialize
       super
       @@evaluators['one-to-one'] = OneToOne.new @@action_store
       @@evaluators['one-to-many'] = OneToMany.new @@action_store
    end

     aget %r{#{CLIENTS}$} do |uuid|
      em_get( "/clients/#{uuid}" ) do |response|
        if response[:status] == 200
          body { response[:content] }
        else
          status 404
          body { {:error => "Client with uuid #{uuid} was not found"}.to_json }
        end
      end
    end

    aput %r{#{CLIENTS}/environment$} do |uuid|
      logger.info "202"
      authorized_request do |account|
        request_body = request.body.read
        puts "#{uuid} PUT: #{request_body}"
        em_put( "/clients/#{uuid}/environment", request_body ) do |response|
          status 201
          body { response[:content] }
        end
      end
    end

    adelete %r{#{CLIENTS}/environment$} do |uuid|
      em_delete("/clients/#{uuid}/delete") do |response|
        status 200
        body {"deleted"}
      end
    end

    aput %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      payload = JSON.parse( request.body.read )

      action  = {
        :mode     => action_name,
        :type     => :sender,
        :payload  => payload,
        :request  => self,
        :uuid    => uuid
      }

      @@evaluators[action_name].add action
    end

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      action = {
        :mode     => action_name,
        :type     => :receiver,
        :request  => self,
        :uuid     => uuid,
        :waiting  => params['waiting'] || false
      }
      @@evaluators[action_name].add action
    end

    # javascript routes
    aget %r{#{CLIENTS}/environment.js$} do |uuid|
      authorized_request do
        environment = Hash.new
        environment["gps"] = {
          "latitude" => params["latitude"].to_f,
          "longitude" => params["longitude"].to_f,
          "accuracy" => params["accuracy"].to_f,
          "timestamp" => params["timestamp"].to_f
        }

        environment["wifi"] = {
          "bssids"    => params["bssids"],
          "timestamp" => Time.now.to_i
        }

        puts "put body #{environment}"
        em_put( "/clients/#{uuid}/environment", environment.to_json ) do |response|
          status 201
          body {"#{params['jsonp']}(#{environment.to_json})"}
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
        :jsonp_method => params["jsonp"]
      }

      @@evaluators[params["mode"]].add action
    end

    aget %r{#{CLIENTS}/action/receive.js$} do |uuid|
      action = {
        :mode         => params["mode"],
        :type         => :receiver,
        :request      => self,
        :uuid         => uuid,
        :jsonp_method => params["jsonp"],
        :waiting      => params["waiting"] || false
      }

      @@evaluators[params["mode"]].add action
    end

  end

end
