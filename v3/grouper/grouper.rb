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
      environment_data   = JSON.parse( request_body )
      
      if environment = Environment.where( :client_uuid => uuid ).first
        environment.update_attributes(environment_data)
        environment.save
      else  
        Environment.create( environment_data.merge!( :client_uuid => uuid ) )
      end
      
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
    
    delete %r{/clients/(.{36,36})/delete} do |uuid|
      Environment.delete_all(:conditions => { :client_uuid =>  uuid })
    end    
  end
end