require 'net/http'
require 'json'

class Client

  def initialize lat=nil, long=nil, accuracy=nil

<<<<<<< HEAD
    response = http_post "http://127.0.0.1/clients", '{"client" : "ruby tester"}'
=======
    response = http_post "http://beta.hoccer.com/v3/clients", "{client:'ruby tester'}"
>>>>>>> c3980f351ca3ec0812db2d4b4c2ac8a866fe9f2f
    @uri = JSON.parse(response)[:uri]

    set_gps lat, long, accuracy if lat
  end

  def set_gps lat, long, accuracy
    environment = {:gps => {:latitude => lat, :longitude => long, :accuracy => accuracy}}

    http_put "#{@uri}/environment", "{environment.to_json}"
  end

  def share mode, payload
    http_post "#{@uri}/action/#{mode}", "#{payload}"
    raise NoOneReceivedError
  end

  def receive mode
    http_get "#{@uri}/action/#{mode}"
  end

  private

  def http_get uri
    uri = URI.parse(uri)
<<<<<<< HEAD
    Net::HTTP.start(uri.host, 9292) {|http|
=======
    Net::HTTP.start(uri.host) {|http|
>>>>>>> c3980f351ca3ec0812db2d4b4c2ac8a866fe9f2f
      response = http.get uri.path
      raise NoOneSharedError if response.code == 410
      raise CollisionError if response.code == 409
      return response.body
    }
  end

  def http_put uri, payload
    uri = URI.parse(uri)
<<<<<<< HEAD
    Net::HTTP.start(uri.host, 9292) {|http|
=======
    Net::HTTP.start(uri.host) {|http|
>>>>>>> c3980f351ca3ec0812db2d4b4c2ac8a866fe9f2f
      return (http.request_put uri.path, payload).body
    }
  end

  def http_post uri, payload
    uri = URI.parse(uri)
<<<<<<< HEAD
    Net::HTTP.start(uri.host, 9292) {|http|
=======
    Net::HTTP.start(uri.host) {|http|
>>>>>>> c3980f351ca3ec0812db2d4b4c2ac8a866fe9f2f
      response = http.request_post uri.path, payload
      raise NoOneReceivedError if response.code == 410
      raise CollisionError if response.code == 409
      return response.body
    }
  end

end

class NoOneSharedError < RuntimeError
end

class NoOneReceivedError < RuntimeError
end

class CollisionError < RuntimeError
end
