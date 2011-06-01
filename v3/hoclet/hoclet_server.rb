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

put '/hoclets/:address/receipt' do |address|
  content = request.body.read
  
  hoclet  = Hoclet.find_by_address_or_create(address, client)
  hoclet[:receipt] = content
  
  hoclet.save
end

put '/hoclets/:address' do |address|
  content = request.body.read
  
  hoclet  = Hoclet.find_by_address_or_create(address, client)
  hoclet[:content] = content
  
  hoclet.save
end

post '/hoclets/:address/transaction' do |address|
  content = JSON.parse(request.body.read)
  
  sender   = content["sender"]
  receiver = content["receiver"]
  
  sender_hoclet   = Hoclet.where(:address => address, :owner => sender).first
  receiver_hoclet = Hoclet.find_by_address_or_create(address, receiver)
  
  if (sender_hoclet.nil?) 
    [404, "not found"]
    return
  end
  
  receiver_hoclet[:receipt] = sender_hoclet[:receipt]
  receiver_hoclet[:content] = sender_hoclet[:content]
  
  sender_hoclet[:previous_content] = sender_hoclet[:content]
  sender_hoclet[:content] = sender_hoclet[:receipt]
  
  sender_hoclet.save
  receiver_hoclet.save
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