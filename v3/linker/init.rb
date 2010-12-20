$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
# Require Libraries
require 'bundler/setup'
require 'yaml'
require 'eventmachine'
require 'em-mongo'
require 'async-rack'
require 'sinatra/async'
require 'sinatra/async/test'
require 'uuid'
require 'json'
require 'hoccer'
require 'thin'

class Numeric
  def to_rad
    self * (Math::PI / 180)
  end
end

def config_file_path filename
  File.join( File.dirname(__FILE__), 'config', filename )
end

def load_config
  puts puts ">>>>>>>>>>>>>>>> #{ENV["RACK_ENV"].upcase} <<<<<<<<<<<<<<<<<"
  Hoccer.instance_eval do
    def config
      puts config_file_path("#{ENV["RACK_ENV"]}.yml")
      @config ||= YAML.load_file( config_file_path("#{ENV["RACK_ENV"]}.yml") )
    end
  end
end

load_config
