module Hoccer
  class App < Sinatra::Base
    register Sinatra::Async

    # Initial client registration
    apost "/clients" do

      db = EM::Mongo::Connection.new.db('hoccer')
      collection = db.collection('people')
      debugger
      collection.insert( JSON.parse(params.keys.first) )

      body { params.inspect }
    end

    # Returns client URI
    aget "/client/uuid" do
      # => "http://api.hoccer.com/v3/client/<client_id>"
      db = EM::Mongo::Connection.new.db('hoccer')
      collection = db.collection('people')
      collection.find do |result|
        body { result.inspect }
      end
    end

    # Writes environment updates
    aput "/client/:uuid/environment" do
      body "bang"
    end

    adelete "/client/:uuid/environment" do
      body "baz"
    end

    # Sharing and Pairing

    # Share
    apost "/client/:uuid/action/:action" do
      # => Redirect http://api.hoccer.com/v3/client/action/id
      EM.add_timer(7) { body { "boom" } }
    end

    # Admin view for action ( Long Polling )
    aget "/client/:uuid/action/:id" do
      body "hello async"
    end

    # Receive ( Long Polling )
    aget "/client/:uuid/action/:action" do |uuid, action|
      body  "foo + #{action} + #{uuid}"
    end

  end
end
