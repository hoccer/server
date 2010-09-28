$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'init'

# Change this to EM.epoll on linux
EM.kqueue

run Hoccer::App
