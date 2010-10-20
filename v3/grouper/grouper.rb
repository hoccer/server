$LOAD_PATH.unshift( File.join( File.dirname( __FILE__), "lib"))

require 'sinatra'
require 'mongoid'
require 'environment'

class Numeric
  def to_rad
    self * (Math::PI / 180)
  end
end

set :run

module Grouper
  class App
  
    get "/" do
    end
    
    get %r{/clients/([a-f0-9]{32,32}$)} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      environment ? environment.to_json : 404
    end
    
    put %r{/clients/([a-f0-9]{32,32})/environment} do |uuid|
      request_body  = request.body.read
      environment   = JSON.parse( request_body )
      environment.merge!( :client_uuid => uuid )
    
      Environment.create( environment )
      
      "OK"
    end
    
    get %r{/clients/([a-f0-9]{32,32})/group} do |uuid|
      client       = Environment.where(:client_uuid => uuid).first
      client.group.to_json
    end
    
  end
end