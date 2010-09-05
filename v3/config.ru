$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'eventmachine'
require 'sinatra'
require 'sinatra/async'
require 'hoccer'

EM.kqueue? ? EM.kqueue : EM.epoll

run Hoccer::App
