module Pass
  
  def seeder
    "SweepOut"
  end
  
  def peer
    "SweepIn"
  end
  
  def collisions?
    (1 < number_of_peers) || (1 < number_of_seeders)
  end

  def number_of_peers
    event_group.events.with_type( peer ).count
  end

  def number_of_seeders
    event_group.events.with_type( seeder ).count
  end
  
  def info_hash
    linked_events = nearby_events
    
    if collisions?
      {
        :state        => :collision,
        :message      => "Your hoc was intercepted. Try again.", # David said so
        :uploads      => Event.extract_uploads(linked_events),
        :peers        => linked_events.size,
        :status_code  => 409
      }
    elsif !expired?
      info = {
        :state        => :waiting,
        :message      => "waiting for other participants",
        :expires      => ( ending_at - Time.now ),
        :peers        => linked_events.size,
        :status_code  => 202
      }
      
      if self.class == SweepOut
        info.merge(:upload_uri => upload.uuid)
      else
        info
      end
      
    elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
      {
        :state        => :no_peers,
        :message      => "Nobody caught your content.",
        :uploads      => [],
        :expires      => 0,
        :peers        => linked_events.size,
        :status_code  => 410
      }
    elsif expired? && 0 == number_of_seeders && 0 < number_of_peers
      {
        :state        => :no_seeders,
        :message      => "Nothing was thrown to you.",
        :uploads      => [],
        :expires      => 0,
        :peers        => linked_events.size,
        :status_code  => 410
      }
    elsif expired? && 0 < number_of_seeders && 0 < number_of_peers
      {
        :state        => :ready,
        :message      => "content available for download",
        :uploads      => Event.extract_uploads(nearby_events(:types => seeder)),
        :peers        => linked_events.size,
        :status_code  => 200
      }
    end
  end
  
end