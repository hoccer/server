$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ruby-debug'
require 'eventmachine'
require 'em-mongo'
require 'sinatra/async'
require 'json'
require 'hoccer'

run Hoccer::App
