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

    set :public, File.join(File.dirname(__FILE__), '..', '/public')

    @@action_store  = ActionStore.new
    @@evaluators    = {}

    def initialize
      super
      @@evaluators['one-to-one']  = OneToOne.new @@action_store
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
        request_hash = JSON.parse( request_body )
        request_hash.merge!( :api_key => params["api_key"] )

        puts "#{uuid} PUT: #{request_body}"
        em_put( "/clients/#{uuid}/environment", request_hash.to_json ) do |response|
          status 201
          body { response[:content] }
        end

        if data = (request_hash["gps"] || request_hash["network"])
          http = EM::Protocols::HttpClient.request(
            :host => "localhost",
            :port => 8090,
            :verb => 'PUT',
            :request => "/hoc",
            :content => data.to_json
          )
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
        :uuid     => uuid,
        :api_key  => params["api_key"]
      }

      @@evaluators[action_name].add action
    end

    aget %r{#{CLIENTS}/action/([\w-]+)$} do |uuid, action_name|
      action = {
        :mode     => action_name,
        :type     => :receiver,
        :request  => self,
        :uuid     => uuid,
        :waiting  => ( params['waiting'] || false ),
        :api_key  => params["api_key"]
      }
      @@evaluators[action_name].add action
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
