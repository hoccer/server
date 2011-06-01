$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'sinatra'
require 'mongoid'

require 'hoclet'

configure do
   Mongoid.configure do |config|
    name = "hoclet"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.slaves = [
      Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
    ]
    config.persist_in_safe_mode = false
  end
end

put '/hoclets/:address' do |address|
  content = request.body.read
  
  hoclet  = Hoclet.where(
    :address => address, 
    :owner => client
  ).first

  if (hoclet.nil?)
    hoclet = Hoclet.new(
      :address => address, 
      :owner => client,
      :content => content
    )
  else
    hoclet[:content] = content
  end
  
  hoclet.save
end

get '/hoclets/:address' do |address| 
  puts client
  hoclet = Hoclet.where(:address => address, :owner => client).first
  
  if (hoclet.nil?) 
    [404, "not found"]
  else
    hoclet[:content]
  end
end

private

def client
  request.cookies["client"]
end