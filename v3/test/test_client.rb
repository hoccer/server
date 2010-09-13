class TestClient

  UUID = /[a-f0-9]{32,32}/

  attr_accessor :uuid

  def self.create
    client = self.new
    client.register
    client
  end

  def initialize
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

  def register
    @uuid = post("/clients").header['Location'].match(UUID)[0]
  end

  def update_environment data
    put(environment_path, data.to_json)
  end

  def share mode, data
    response = post(action_path(mode), data.to_json)
    @redirect_location = response.header['Location']
    response
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
    if @redirect_location
      t = Thread.new do
        Net::HTTP.start(@server, @port) {|http|
          http.get( @redirect_location )
        }
      end
      t.value
    end
  end

  def delete_environment
    Net::HTTP.start(@server, @port) {|http|
      req = Net::HTTP::Delete.new(environment_path)
      response = http.request(req)
    }
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
