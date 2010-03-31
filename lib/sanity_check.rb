class SanityCheck
  
  def self.false_positive
    e = Event.last
    
    options = {
      :starting_at => (e.starting_at - 7.seconds),
      :ending_at => (e.ending_at + 7.seconds),
      :latitude => e.latitude,
      :longitude => e.longitude,
      :types => "Throw",
      :accuracy => e.location_accuracy
    }
    
    result = e.via_locations(options).length
    
    puts result.inspect
  end
  
  def self.check_seeders
    counter = 0;
    
    Event.find_in_batches(:batch_size => 100, :conditions => {:state => "no_peers"}) do |events|
      
      events.each do |event|
        
        result = event.via_locations(
          :starting_at  => (event.starting_at - 60.seconds),
          :ending_at    => (event.ending_at + 60.seconds),
          :accuracy     => 10000,
          :types        => "Catch",
          :latitude     => event.latitude,
          :longitude    => event.longitude
        ).length
        
        if 0 < result
          puts "More peers available for event #{event.id}"
        end
        
      end
      
      counter += 100
      print '.'; $stdout.flush
    end
  end
  
  
  def self.check_peers time_delta, accuracy_override = nil
    counter         = 0;
    result_counter  = 0;
    
    Event.all(:conditions => {:state => "no_seeders"}).each do |e|  
      result =  e.via_locations(
          :starting_at => (e.starting_at - time_delta),
          :ending_at => (e.ending_at + time_delta),
          :latitude => e.latitude,
          :longitude => e.longitude,
          :types => "Throw",
          :accuracy => (accuracy_override || e.accuracy)
      ).length
      
      result_counter+=1 if 0 < result
      
      counter += 1
      
      if (counter % 10000) == 0
        puts counter
        #print '.'; $stdout.flush
      end
    end
    
    result_counter
  end
  
  def self.peers_by_time
    (1..14).each do |i|
      puts "#{i}\t#{SanityCheck.check_peers(i)}"
    end
  end
  
end