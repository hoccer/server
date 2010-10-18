require 'client'
require 'action'

module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async

    @@server    = "localhost"
    @@port      = 4567
    @@pool      = {}
    @@requests  = {}

    def em_request path, method, content, &block
      http = EM::Protocols::HttpClient.request(
        :host => @@server,
        :port => @@port,
        :verb => method   ||= "GET",
        :request => path  ||= "/",
        :content => content
      )

      http.callback do |response|
        puts response[:status]
        puts response[:headers]
        block.call( response )
      end
    end

    aget %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      em_request( "/clients/#{uuid}", nil, nil ) do |response|
        if response[:status] == 200
          body { response[:content] }
        else
          status 404
          body { {:error => "Not Found"}.to_json }
        end
      end
    end

    aput %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      em_request( "/clients/#{uuid}/environment", "PUT", request.body.read ) do |response|
        status 201
        body { "Created" }
      end
    end

    delete %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|

    end

    apost %r{/clients/([a-f0-9]{32,32})/action/([\w-]+)} do |uuid, action_name|
      em_request( "/clients/#{uuid}/group", nil, request.body.read ) do |response|
        @@pool

        body { response[:content].inspect }
      end
    end

    aget %r{/clients/([a-f0-9]{32,32})/action/([\w-]+)} do |uuid, action_name|
      body { "geht auch" }
    end

  end

end
