require 'sinatra'

module Hoccer
  class Grouper < Sinatra::Base
    set :show_exceptions, false # we render our own errors

    error do
      e = request.env['sinatra.error'];
      "#{e.class}: #{e.message}\n"
    end

    not_found do
      { :message => "Not Found" }.to_json
    end

    get "/" do
      "I'm the grouper!"
    end

    put %r{/clients/(.{36,36})/environment} do |uuid|
      request_body  = request.body.read
      environment_data = JSON.parse( request_body )
      
      if environment_data["selected_clients"]
        environment_data["selected_clients"] = environment_data["selected_clients"].map do |hash|
          Lookup.reverse_lookup(hash)
        end
      end
      
      if environment = Environment.first({ :conditions => {:client_uuid => uuid} })
        environment.destroy
      end
      env = Environment.create( environment_data.merge!( :client_uuid => uuid ) )

      result = { 
        :hoccability => Hoccability.analyze(env),
        :group       => env.grouped_envs.map do |e| 
          { 
            :client_uuid => e.client_uuid, 
            :anonymized => Lookup.lookup_uuid(e.client_uuid), 
            :client_name => e[:client_name]
          } 
        end
      }
      
      result.to_json
    end

    get %r{/clients/(.{36,36})/group} do |uuid|
      client = Environment.newest uuid
            
      if client && client.all_in_group
        g = client.all_in_group.map do |e| 
          info = { 
            :client_uuid => e.client_uuid,
            :anonymized => Lookup.lookup_uuid(e.client_uuid), 
            :client_name => e[:client_name],
          }
          if e[:pubkey]
            info[:public_key_hash]= Digest::SHA256.hexdigest(e[:pubkey])[0..7]
          end
          info
        end
        
        g.to_json
      else
        halt 200, [].to_json
      end
    end
    
    get %r{/clients/(.{36,36})/selected_group} do |uuid|
      client = Environment.newest uuid
            
      if client && client.group
        client.group.to_json
      else
        halt 200, [].to_json
      end    
    end
    
    get %r{/clients/(.{36,36})$} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      environment ? environment.to_json : 404
    end
    
    get %r{/clients/(.{36,36})/(.+)/publickey$} do |uuid, hashid|
      clientid = Lookup.reverse_lookup(hashid)
      environment = Environment.where(:client_uuid => clientid).first
      publickey = environment[:pubkey]
      publickey ? publickey : 404
    end

    delete %r{/clients/(.{36,36})/delete} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      return unless environment
      
      group = environment.all_in_group
      environment.destroy
      
      updated_clients = []
      group.each do |g|
        if g != environment
          updated_clients << g["client_uuid"]
        end
      end
            
      status 200
      updated_clients.to_json
    end

    get %r{/clients/(.{36,36})/delete} do |uuid|
      Environment.delete_all(:conditions => { :client_uuid =>  uuid })
    end

    get "/debug" do
      @groups = Environment.only(:group_id).group
      erb :debug
    end
  end
end
