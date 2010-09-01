$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra/async'
require 'hoccer'

run Hoccer::App
