module Hoccer
  module Cache
    
    def peer
      "Pick"
    end
    
    def seeder
      "Drop"
    end
    
    def info_hash
      {}
    end
    
    def collisions?
      false
    end
    
    def expired?
      true
    end
    
    def number_of_peers
      if peer?
        nearby_events.count + 1
      else
        nearby_events.count
      end
    end
  
    def number_of_seeders
      seeders = nearby_events.select do |e|
        e.upload && e.upload.attachment_file_name
      end
      
      if seeder?
        seeders.length + 1
      else
        seeders.length
      end
    end
    
    def expiration_time
      Event.first(
        :select => "ending_at, created_at, event_group_id",
        :conditions => {:event_group_id => event_group_id},
        :order => "created_at ASC"
      ).ending_at
    end
    
    def info_hash
      linked_events = nearby_events
      
      result = case current_state
        
      # when :waiting
      #   {
      #     :state        => "waiting",
      #     :message      => "waiting for other participants",
      #     :expires      => expires,
      #     :peers        => (linked_events - [self]).size,
      #     :status_code  => 202
      #   }
      #   
      # when :collision
      #   {
      #     :state        => "collision",
      #     :message      => "waiting for other participants",
      #     :expires      => 0,
      #     :peers        => (linked_events - [self]).size,
      #     :status_code  => 409
      #   }
      #   
      when :no_peers
        {
          :state        => "waiting",
          :message      => "waiting for other participants",
          :expires      => (ending_at - Time.now).ceil,
          :peers        => (linked_events - [self]).size,
          :status_code  => 202
        }
        
      when :no_seeders
        {
          :state        => "empty_cache",
          :message      => "Nothing to pick up from this location",
          :status_code  => 424
        }
        
      when :ready
        
        {
          :state        => "ready",
          :message      => "Content ready for downloading",
          :expires      => 0,
          :peers        => (linked_events - [self]).size,
          :uploads      => Event.extract_uploads(linked_events),
          :status_code  => 200
        }
        
      when :canceled
        {
          :state        => :canceled,
          :message      => "Event was canceled",
          :uploads      => [],
          :expires      => 0,
          :peers        => (linked_events - [self]).size,
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
end