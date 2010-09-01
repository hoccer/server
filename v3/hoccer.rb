require 'eventmachine'
module Hoccer

  class App < Sinatra::Base
    register Sinatra::Async

    aget "/high" do
      EM.add_timer(3) { body { "delayed for #{3} seconds" } }
    end

    # Initial client registration
    post "/client" do
      # 1. Create Client Object
      # 2. Create Client Environment
      # => redirect http://api.hoccer.com/v3/client/<client_id>
    end

    # Returns client URI
    get "/client/:uuid" do
      # => "http://api.hoccer.com/v3/client/<client_id>"
    end

    # Writes environment updates
    put "/client/:uuid/environment" do
      # => 200 OK
    end

    delete "/client/:uuid/environment" do
      # => 200 OK
    end

    # Sharing and Pairing

    # Share
    post "/client/:uuid/action/:id" do
      # => Redirect http://api.hoccer.com/v3/client/action/id
    end

    # Admin view for action ( Long Polling )
    get "/client/:uuid/action/:id" do

    end

    # Receive ( Long Polling )
    aget "/client/:uuid/action/:action" do
      # => { json : data }
    end

  end

end

__END__

Writing the environment

Long polling gers
