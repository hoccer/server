$LOAD_PATH.unshift( File.join( File.dirname( __FILE__), "lib"))

require 'sinatra'
require 'mongoid'
require 'environment'

class Numeric
  def to_rad
    self * (Math::PI / 180)
  end
end

module Grouper
  class App < Sinatra::Base
  
    get "/" do
      "Hallo"
    end
    
    put %r{/clients/(.{36,36})/environment} do |uuid|
      request_body  = request.body.read
      puts request_body
      environment   = JSON.parse( request_body )
            
      environment.merge!( :client_uuid => uuid )
      Environment.create( environment )
      
      "OK"
    end
    
    get %r{/clients/(.{36,36})/group} do |uuid|
      client       = Environment.newest uuid
      client.group.to_json
    end
    
    get %r{/clients/(.+$)} do |uuid|
       environment = Environment.where(:client_uuid => uuid).first
       environment ? environment.to_json : 404
     end
    
    
  end
end