$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'active_record'
require 'active_support'
require 'eventmachine'
require 'sinatra/async'
require 'hoccer'

run Hoccer::App
