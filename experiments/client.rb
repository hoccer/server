require "rubygems"
require "active_support"
require 'digest/sha1'


class Client

  def initialize lat=nil, long=nil, accuracy=nil
    #@simulate = true;

    server = "http://api.hoccer.com"
    http_post "#{server}/v3/clients"
    id = Digest::SHA1.hexdigest Time.now.to_s
    @client_uri = "#{server}/v3/clients/#{id}"

    set_gps lat, long, accuracy
  end

  def set_gps lat, long, accuracy
    environment = {:gps => {:latitude => lat, :longitude => long, :accuracy => accuracy}}

    http_put "#{@client_uri}/environment\n#{environment.to_json}"
  end

  def send mode, payload
    http_post "#{@client_uri}/action/#{mode}\n#{payload}"
  end

  def receive mode
    http_get "#{@client_uri}/action/#{mode}"
  end

  private

  def http_get uri
    unless @simulate

    else
      puts "GET #{uri}"
      "no data in simulation mode"
    end

  end

  def http_put uri
    unless @simulate

    else
      puts "PUT #{uri}"
    end
  end

  def http_post uri
    unless @simulate

    else
      puts "POST #{uri}"
      "no data in simulation mode"
    end
  end

end


