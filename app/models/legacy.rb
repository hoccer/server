module Legacy
  
  module Distribute
    def collisions?
      1 < event_group.events.with_type( "LegacyThrow" ).count
    end

    def number_of_peers
      Event.with_type( "LegacyCatch" ) .
      all(:conditions => {:event_group_id => event_group_id}) .
      count
    end

    def number_of_seeders
      Event.with_type( "LegacyThrow" ) .
      all(:conditions => {:event_group_id => event_group_id}) .
      count
    end
  end
  
  module Share
    def collisions?
      (1 < event_group.events.with_type( "LegacyPass" ).count) ||
      (1 < event_group.events.with_type( "LegacyReceive" ).count)
    end

    def number_of_peers
      Event.with_type( "LegacyReceive" ) .
      all(:conditions => {:event_group_id => event_group_id}) .
      count
    end

    def number_of_seeders
      Event.with_type( "LegacyPass" ) .
      all(:conditions => {:event_group_id => event_group_id}) .
      count
    end
    
  end
  
  module General
    def legacy?
      true
    end
    
    def info
      linked_events = event_group.events.with_type( linkable_type )
      # can you smell the state machine ?
    
      if collisions?
        {
          :state => :collision,
          :message => "Unfortunatly your hoc was intercepted. Try again.",
          :expires => 0,
          :resources => [],
          :status_code => 409
        }
      elsif !expired?
        {
          :state => :waiting,
          :message => expires.to_s,
          :expires => expires,
          :resources => [],
          :status_code => 202
        }
      elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
        {
          :state => :no_peers,
          :message => "Nobody caught your content.",
          :expires => 0,
          :resources => [],
          :status_code => 500
        }
      elsif expired? && 0 == number_of_seeders && 0 < number_of_peers
        {
          :state => :no_seeders,
          :message => "Nothing was thrown to you.",
          :expires => 0,
          :resources => [],
          :status_code => 500
        }
      elsif expired? && 0 < number_of_seeders && 0 < number_of_peers
        {
          :state => :ready,
          :message => "Downloading content",
          :expires => 0,
          :resources => ((upload = linked_events.first.upload) ? upload.uuid : []),
          :status_code => 200
        }
      end
    
    end
  end
    
end
