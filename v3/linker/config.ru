$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'init'

# Change this to EM.epoll on linux
EM.kqueue

run Hoccer::App
