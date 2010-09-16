require 'json'
require 'net/http'

class TestClient

  UUID = /[a-f0-9]{32,32}/

  attr_accessor :uuid

  def initialize
    @server = "127.0.0.1"
    @port   = 9292
  end

  def drop data
    post "/store", data.to_json
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
