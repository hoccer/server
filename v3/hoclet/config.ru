$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'hoclet_server'

run HocletServer::App
