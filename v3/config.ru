$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'init'

EM.kqueue? ? EM.kqueue : EM.epoll

run Hoccer::App
