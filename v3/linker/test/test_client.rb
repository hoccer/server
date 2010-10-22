class TestClient

  attr_accessor :uuid

  def self.create
    client = self.new
    client
  end

  def initialize
    @uuid = UUID.generate
    @server = "127.0.0.1"
    @port   = 9292
  end

  def client_path
    "/clients/#{@uuid}"
  end

  def environment_path
    "/clients/#{@uuid}/environment"
  end

  def action_path mode
    "/clients/#{@uuid}/action/#{mode}"
  end

  def update_environment data
    put(environment_path, data.to_json)
  end

  def share mode, data
    response = post(action_path(mode), data.to_json)
    @redirect_location = response.header['Location']
    response
  end

  def receive_unthreaded mode
    Net::HTTP.start(@server, @port) {|http|
      http.get( action_path(mode) )
    }
  end

  def receive mode
    t = Thread.new do
      Net::HTTP.start(@server, @port) {|http|
        http.get( action_path(mode) )
      }
    end
    t.value
  end

  def follow_redirect
    t = Thread.new do
        follow_redirect_unthreaded
    end
    t.value
  end

  def follow_redirect_unthreaded
    if @redirect_location
      url = URI.parse @redirect_location
      Net::HTTP.start(url.host, url.port) {|http|
        http.get( url.path )
      }
    end
  end

  def delete_environment
    req = Net::HTTP::Delete.new(environment_path)
    Net::HTTP.start(@server, @port) do |http|
      response = http.request(req)
    end
  end

  def request method, path, data = ""
    Net::HTTP.start(@server, @port) do |http|
      http.send( "request_#{method}".to_sym, path, data )
    end
  end

  def method_missing name, *args
    if %w(get post put delete).include? name.to_s
      request name, *args
    else
      super
    end
  end

end
