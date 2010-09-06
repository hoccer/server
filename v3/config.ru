$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'eventmachine'
require 'sinatra'
require 'sinatra/async'
require 'uuid'
require 'json'
require 'hoccer'

EM.kqueue? ? EM.kqueue : EM.epoll

run Hoccer::App
