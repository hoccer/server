class SanityCheck
  
  def self.check_seeders
    counter = 0;
    
    Event.find_in_batches(:batch_size => 10, :conditions => {:state => "no_peers"}) do |events|
      
      events.each do |event|
        
        result = event.nearby_events(
          :starting_at  => (event.starting_at - 60.seconds),
          :ending_at    => (event.ending_at + 60.seconds),
          :accuracy     => 10000
        ).length
        
        if 0 < result
          puts "More peers available for event #{event.id}"
        else
          puts "No other peers available"
        end
        
      end
      
      counter += 10
      puts counter
    end
  end
  
  
  
end