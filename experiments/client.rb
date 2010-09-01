require "rubygems"
require "active_support"
require 'digest/sha1'

class Client

  def initialize
    server = "http://api.hoccer.com"
    puts "POST #{server}/v3/clients"
    id = Digest::SHA1.hexdigest Time.now.to_s
    @client_uri = "#{server}/v3/clients/#{id}"

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

c = Client.new
c.set_environment 2, 4, 100

c.send :pass, "{keks: \"lecker\"}"
c.receive :pass

