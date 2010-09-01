require "rubygems"
require "active_support"
require 'digest/sha1'

class Client

  def initialize lat=nil, long=nil, accuracy=nil
    server = "http://api.hoccer.com"
    puts "POST #{server}/v3/clients"
    id = Digest::SHA1.hexdigest Time.now.to_s
    @client_uri = "#{server}/v3/clients/#{id}"

    set_environment lat, long, accuracy
  end

  def set_environment lat, long, accuracy
    environment = {:latitude => lat, :longitude => long, :accuracy => accuracy}

    puts "PUT #{@client_uri}/environment\n{gps: #{environment.to_json}}"
  end

  def send mode, payload
    puts "POST #{@client_uri}/action/#{mode}\n#{payload}"
  end

  def receive mode
    puts "GET #{@client_uri}/action/#{mode}"
  end

end


