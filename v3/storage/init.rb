# Require Libraries
require 'bundler/setup'
require 'eventmachine'
require 'async-rack'
require 'sinatra/async'
require 'sinatra/async/test'
require 'em-mongo'
require 'uuid'
require 'json'
require 'hoccer'

class Numeric
  def to_rad
    self * (Math::PI / 180)
  end
end
