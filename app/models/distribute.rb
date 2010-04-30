module Distribute
  
  def seeder
    "Throw"
  end
  
  def peer
    "Catch"
  end
  
  def collisions?
    1 < number_of_seeders
  end

  def number_of_peers
    event_group.events.with_type( peer ).count
  end

  def number_of_seeders
    event_group.events.with_type( seeder ).count
  end
  
  def latest_in_group
    Event.first(
      :select => "ending_at, created_at, event_group_id",
      :conditions => {:event_group_id => event_group_id},
      :order => "created_at ASC"
    ).ending_at
  end
  
  def info_hash
    result = case current_state
      
    when :waiting
      {
        :state        => "waiting",
        :message      => "waiting for other participants",
        :expires      => expires,
        :peers        => (event_group.events - [self]).size,
        :status_code  => 202
      }
      
    when :collision
      {
        :state        => "collision",
        :message      => "waiting for other participants",
        :expires      => 0,
        :peers        => (event_group.events - [self]).size,
        :status_code  => 409
      }
      
    when :no_peers
      {
        :state        => "no_peers",
        :message      => "waiting for other participants",
        :expires      => 0,
        :peers        => (event_group.events - [self]).size,
        :status_code  => 410
      }
      
    when :no_seeders
      {
        :state        => "no_seeders",
        :message      => "waiting for other participants",
        :expires      => 0,
        :peers        => (event_group.events - [self]).size,
        :status_code  => 410
      }
      
    when :ready
      {
        :state        => "ready",
        :message      => "content ready for downloading",
        :expires      => 0,
        :peers        => (event_group.events - [self]).size,
        :uploads      => Event.extract_uploads(event_group.events),
        :status_code  => 200
      }
      
    when :canceled
      {
        :state        => :canceled,
        :message      => "Event was canceled",
        :uploads      => [],
        :expires      => 0,
        :peers        => (event_group.events - [self]).size,
        :status_code  => 410
      }
      
    end
    
    if upload
      result.merge({
        :upload_uri => upload.uuid
      })
    else
      result
    end
  end
end