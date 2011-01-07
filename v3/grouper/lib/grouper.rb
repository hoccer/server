module Hoccer
  class Grouper < Sinatra::Base

    error do
      e = request.env['sinatra.error'];
      "#{e.class}: #{e.message}\n"
    end

    get "/" do
      "Hallo"
    end

    put %r{/clients/(.{36,36})/environment} do |uuid|
      request_body  = request.body.read
      environment_data = JSON.parse( request_body )

      if environment = Environment.first({ :conditions => {:client_uuid => uuid} })
        environment.destroy
      end
      Environment.create( environment_data.merge!( :client_uuid => uuid ) )

      {:message => "hallo", :quality => 2}.to_json
    end

    get %r{/clients/(.{36,36})/group} do |uuid|
      client = Environment.newest uuid
      if client && client.group
        client.group.to_json
      else
        halt 404, { :message => "Not Found" }.to_json
      end
    end

    get %r{/clients/(.{36,36})$} do |uuid|
      environment = Environment.where(:client_uuid => uuid).first
      environment ? environment.to_json : 404
    end

    delete %r{/clients/(.{36,36})/delete} do |uuid|
      Environment.delete_all(:conditions => { :client_uuid =>  uuid })
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
