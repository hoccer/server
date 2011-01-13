require 'sinatra'
require 'uuid'
require 'mongoid'
require 'grouper'
require 'environment'
require 'hoccability'
require 'ruby-debug'

def load_config env
  file_name = File.join(File.dirname(__FILE__), "config", "mongoid.yml")
  @settings = YAML.load_file( file_name )

  Mongoid.configure do |config|
    config.from_hash(@settings[env])
  end
end

configure :production do
  puts ">>>>>>>>>>>>>>>> PRODUCTION <<<<<<<<<<<<<<<<<"
  load_config "production"
end

configure :development do
  puts ">>>>>>>>>>>>>>>> DEVELOPMENT <<<<<<<<<<<<<<<<<"
  load_config "development"
end

configure :test do
  puts ">>>>>>>>>>>>>>>> TEST <<<<<<<<<<<<<<<<<"
  load_config "test"
end


