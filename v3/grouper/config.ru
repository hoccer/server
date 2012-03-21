$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'logger'
require 'sinatra'

configure :development do
  LOGGER = Logger.new("thin.log")
  enable :logging, :dump_errors
  set :raise_errors, true
end

require 'init'

run Hoccer::Grouper
