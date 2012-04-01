require 'sinatra'
require 'uuid'
require 'mongoid'
require 'grouper'
require 'environment'
require 'lookup'
require 'hoccability'
require 'ruby-debug'

HOCCER_ENV = ENV["RACK_ENV"]

puts ">>>>>>>>>> Hoccer Grouper for #{HOCCER_ENV.upcase} <<<<<<<<<<"

def load_config env
  file_name = File.join(File.dirname(__FILE__), "config", "mongoid.yml")
  @settings = YAML.load_file( file_name )

  Mongoid.configure do |config|
    config.from_hash(@settings[env])
  end
end

load_config HOCCER_ENV
