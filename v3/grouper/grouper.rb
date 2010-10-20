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
  class App < Sinatra::Base
  
    get "/" do
    end
    
    get %r{/clients/(.+)$} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      environment ? environment.to_json : 404
    end
    
    put %r{/clients/(.+)/environment} do |uuid|
      request_body  = request.body.read
      environment   = JSON.parse( request_body )
      
      environment = ensure_indexable(environment)
      
      environment.merge!( :client_uuid => uuid )
      Environment.create( environment )
      
      "OK"
    end
    
    get %r{/clients/(.+)/group} do |uuid|
      client       = Environment.newest
      client.group.to_json
    end
  end
end