$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'init'

# Change this to EM.epoll on linux

EM.send( Hoccer.config["polling"].to_sym )

run Hoccer::App
