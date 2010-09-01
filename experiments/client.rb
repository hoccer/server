require "rubygems"
require "active_support"
require 'digest/sha1'
require 'net/http'

class Client

  def initialize lat=nil, long=nil, accuracy=nil
    #@simulate = true;

    @server = "localhost"
    id = http_post "#/v3/clients", "{client:'ruby tester'}"
    id = Digest::SHA1.hexdigest Time.now.to_s
    @client_uri = "/v3/clients/#{id}"

    set_gps lat, long, accuracy if lat
  end

  def set_gps lat, long, accuracy
    environment = {:gps => {:latitude => lat, :longitude => long, :accuracy => accuracy}}

    http_put "#{@client_uri}/environment\n#{environment.to_json}"
  end

  def send mode, payload
    http_post "#{@client_uri}/action/#{mode}", "#{payload}"
    raise NoOneReceivedError
  end

  def receive mode
    http_get "#{@client_uri}/action/#{mode}"
  end

  private

  def http_get uri
    unless @simulate
      Net::HTTP.start(@server) {|http|
        response = http.get uri
        raise NoOneSharedError if response.code == 410
        raise CollisionError if response.code == 409
        return response.body
      }
    else
      puts "GET #{uri}"
      "no data in simulation mode"
    end

  end

  def http_put uri, payload
    unless @simulate
      Net::HTTP.start(@server) {|http|
        return (http.request_put uri, payload).body
      }
    else
      puts "PUT #{uri}\n#{payload}"
    end
  end

  def http_post uri, payload
    unless @simulate
      Net::HTTP.start(@server) {|http|
        response = http.request_post uri, payload
        raise NoOneReceivedError if response.code == 410
        raise CollisionError if response.code == 409
        return response.body
      }
    else
      puts "POST #{uri}\n#{payload}"
      "no data in simulation mode"
    end
  end

end

class NoOneSharedError < RuntimeError
end

class NoOneReceivedError < RuntimeError
end

class CollisionError < RuntimeError
end
