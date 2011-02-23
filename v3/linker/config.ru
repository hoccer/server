$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'logger'

class Logger
  def format_message( severity, timestamp, progname, msg )
    "#{msg}\n"
  end
end
MuninLogger = Logger.new('log/munin.log')

require 'init'

# Change this to EM.epoll on linux

EM.kqueue if EM.kqueue?
EM.epoll  if EM.epoll?

run Hoccer::App
