$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'logger'

class Logger
  def format_message( severity, timestamp, progname, msg )
    "#{msg}\n"
  end
end

require 'init'

# Change this to EM.epoll on linux

EM.kqueue if EM.kqueue?
EM.epoll  if EM.epoll?

require 'sinatra'

configure :development do
  LOGGER = Logger.new("thin.log")
  enable :logging, :dump_errors
  set :raise_errors, true
end

run Hoccer::App
