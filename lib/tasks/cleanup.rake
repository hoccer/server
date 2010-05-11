namespace :hoccer do
  
  desc "garbage collect old objects"
  task :gc => :environment do
    
    
    logfile         = "/var/backups/hoccer/gc.log"
    timestamp       = Time.now.strftime("%Y-%m-%d_%H-%M")
    
    pg_dump_command = "sudo -u postgres " \
                      "/usr/bin/pg_dump -Fc hoccer2_production > " \
                      "/var/backups/hoccer/hoccer_live_db_#{timestamp}.backup"
    
    system(pg_dump_command)
    
    @event_group_ids  = []
    
    @statistics       = {
      :events         => { :before => Event.count },
      :event_groups   => { :before => EventGroup.count },
      :uploads        => { :before => Upload.count }
    }
    
    def Event.expired_events
      scoped(:conditions => ["ending_at < ?", 2.hours.ago])
    end
    
    while not (events = Event.expired_events.scoped(:limit => 1000)).empty? do
      events.each do |event|
        @event_group_ids << event.event_group_id
        event.destroy
      end
    end
    
    EventGroup.delete(@event_group_ids.uniq)
    sleep(5)
    
    @statistics[:events][:after]        = Event.count
    @statistics[:event_groups][:after]  = EventGroup.count
    @statistics[:uploads][:after]       = Upload.count
    
    if File.exist?( logfile )
    File.open(logfile, "a+") do |file|
      file.puts 79 * "="
      file.puts timestamp
      file.puts "Events before: #{@statistics[:events][:before]}"
      file.puts "Events after: #{@statistics[:events][:after]}"
      file.puts "EventGroups before: #{@statistics[:event_groups][:before]}"
      file.puts "EventGroups after: #{@statistics[:event_groups][:after]}"
      file.puts "Uploads before: #{@statistics[:uploads][:before]}"
      file.puts "Events after: #{@statistics[:uploads][:after]}"}"
    end
  end
  
  
  
end