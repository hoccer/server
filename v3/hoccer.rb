module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async

    aget "/high" do
      EM.add_timer(3) { body { "delayed for #{3} seconds" } }
    end

    # Initial client registration
    apost "/client" do
      # 1. Create Client Object
      # 2. Create Client Environment
      # => redirect http://api.hoccer.com/v3/client/<client_id>
      # => 200 OK
      body "gaba"
    end

    # Returns client URI
    aget "/client/uuid" do
      # => "http://api.hoccer.com/v3/client/<client_id>"
      body "ok it is"
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
