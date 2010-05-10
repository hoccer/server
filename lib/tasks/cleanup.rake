namespace :hoccer do
  
  desc "garbage collect old objects"
  task :gc => :environment do
    
    @event_group_ids = []
    
    def Event.expired_events
      scoped(:conditions => ["ending_at < ?", 2.hours.ago])
    end
    
    puts "Events before GC: #{Event.count}"
    
    while not (events = Event.expired_events.scoped(:limit => 1000)).empty? do
      events.each do |event|
        @event_group_ids << event.event_group_id
        event.destroy
      end
    end
    
    puts "Events after GC: #{Event.count}"
    
    puts "EventGroups before GC: #{EventGroup.count}"
    puts "EventGroups to be deleted: #{@event_group_ids.uniq.size}"
    EventGroup.delete(@event_group_ids.uniq)
    sleep(5)
    puts "EventGroups after GC: #{EventGroup.count}"
    
  end
  
  
  
end