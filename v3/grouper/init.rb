require 'sinatra'
require 'mongoid'
require 'grouper'
require 'environment'

class Numeric
  def to_rad
    (self * (Math::PI / 180))
  end
end

configure :production do
  puts ">>>>>>>>>>>>>>>> PRODUCTION <<<<<<<<<<<<<<<<<"
end

configure :development do
  puts ">>>>>>>>>>>>>>>> DEVELOPMENT <<<<<<<<<<<<<<<<<"
end

configure :test do
  puts ">>>>>>>>>>>>>>>> TEST <<<<<<<<<<<<<<<<<"
end

file_name = File.join(File.dirname(__FILE__), "config", "mongoid.yml")
@settings = YAML.load_file( file_name )

Mongoid.configure do |config|
  config.from_hash(@settings[ENV['RACK_ENV']])
end
