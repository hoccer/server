require 'sinatra'

module Hoccer
  class Grouper < Sinatra::Base
    set :show_exceptions, false # we render our own errors

    before do
      logs "before request= #{request.request_method} #{request.path_info}"
    end

    error do
      e = request.env['sinatra.error'];
      "#{e.class}: #{e.message}\n"
    end

    not_found do
      { :message => "Not Found" }.to_json
    end

    # say hello when spoken to

    get "/" do
      "This is the Hoccer Grouper in the #{HOCCER_ENV} environment."
    end

    # PUT request to set environment data for client (location etc.)

    put %r{/clients/(.{36,36})/environment} do |uuid|

      # parse environment data

      request_body  = request.body.read
      environment_data = JSON.parse( request_body )

      logs "environment update for client #{uuid}: #{environment_data.inspect}"

      # replace hash ids of selected clients with uuids

      if environment_data["selected_clients"]
        environment_data["selected_clients"] = environment_data["selected_clients"].map do |hash|
          Lookup.reverse_lookup(hash)
        end
      end

      # delete environment entry for this uuid if existing and create new one using environment data

      if environment = Environment.first({ :conditions => {:client_uuid => uuid} })
        environment.destroy
      end
      env = Environment.create( environment_data.merge!( :client_uuid => uuid ) )

      # return hoccability and group info

      result = {
        :hoccability => Hoccability.analyze(env),
        :group       => env.grouped_envs.map do |e|
          member = {
            :client_uuid => e.client_uuid,
            :anonymized => Lookup.lookup_uuid(e.client_uuid), # hash id belonging to uuid
            :client_name => e[:client_name],
          }
          if e[:pubkey_id]
            member[:pubkey_id] = e[:pubkey_id]
          end
          member
        end
      }
      logs "returning data for client #{uuid} after environment update: #{result.inspect}"
      result.to_json
    end

    # GET request to receive group information for client
    # (all clients grouped together based on proximity with environment updates in the last 40s)

    get %r{/clients/(.{36,36})/group} do |uuid|

      # find client belonging to uuid

      client = Environment.newest uuid

      # get relevant data for clients belonging to same group

      if client && client.all_in_group

        # create and return group info

        g = client.all_in_group.map do |e| 
          info = { 
            :client_uuid => e.client_uuid,
            :anonymized => Lookup.lookup_uuid(e.client_uuid), # hash id belonging to uuid
            :client_name => e[:client_name],
          }
          if e[:pubkey]
            info[:pubkey_id]= e[:pubkey_id]
          end
          info
        end
        
        logs "returning group of client #{uuid}: #{g.inspect}"
        g.to_json
      else
        logs "returning group of client #{uuid}: []"
        halt 200, [].to_json # if group is empty
      end
    end

    # GET request to receive selected group information for client
    # (as in group request, filtered by selected clients)

    get %r{/clients/(.{36,36})/selected_group} do |uuid|
      client = Environment.newest uuid
            
      if client && client.group
        logs "returning selected group of client #{uuid}: #{client.group.inspect}"
        client.group.to_json
      else
        logs "returning selected group of client #{uuid}: []"
        halt 200, [].to_json
      end    
    end

    # GET request to receive environment data for client

    get %r{/clients/(.{36,36})$} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      if environment
        logs "returning environment data for client #{uuid}"
        environment.to_json
      else
        logs "no environment data found for client #{uuid}"
        404
      end
    end

    # GET request to receive the public key associated with a hash id

    get %r{/clients/(.{36,36})/(.{8,8})/publickey$} do |uuid, hashid|
      environment = Environment.where(:pubkey_id => hashid).first
      publickey = environment[:pubkey]
      if publickey
        logs "returning public key for hash id #{hashid}: #{publickey.inspect}"
        publickey
      else
        logs "no public key found for hash id #{hashid}"
        404
      end
    end

    # DELETE request to sign off client

    delete %r{/clients/(.{36,36})/delete} do |uuid|

      # find client belonging to uuid

      environment = Environment.where(:client_uuid => uuid).first
      return unless environment
      
      # delete

      group = environment.all_in_group
      environment.destroy

      # return uuids of updated clients in the same group

      updated_clients = []
      group.each do |g|
        if g != environment
          updated_clients << g["client_uuid"]
        end
      end

      logs "client #{uuid} deleted. updated clients: #{updated_clients.inspect}"
            
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

    # write in log with timestamp

    def logs message
      puts "#{Time.now}: #{message}"
    end

  end
end
