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

HOCCER_ENV = ENV["RACK_ENV"]

puts ">>>>>>>>>> Hoccer Linker for #{HOCCER_ENV.upcase} <<<<<<<<<<"

class Numeric
  def to_rad
    self * (Math::PI / 180)
  end
end

def config_file_path
  File.join( File.dirname(__FILE__), 'config', 'hoccer.yml')
end

def load_config env
  Hoccer.instance_eval do
    def config
      begin
        @config ||= YAML.load_file( config_file_path )[env]
      rescue
        raise "Unable to load config/hoccer.yml"
      end
    end
  end
end

load_config HOCCER_ENV
