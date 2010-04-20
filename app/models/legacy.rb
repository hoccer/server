module Legacy
  
  def info_hash
    
    result = case current_state
    when :collision
      {
        :state => :collision,
        :message => "Unfortunatly your hoc was intercepted. Try again.",
        :expires => 0,
        :resources => [],
        :status_code => 409
      }
    when :waiting
      {
        :state => :waiting,
        :message => expires.to_s,
        :expires => expires,
        :resources => [],
        :status_code => 202
      }
    when :no_peers
      {
        :state => :no_peers,
        :message => "Nobody caught your content.",
        :expires => 0,
        :resources => [],
        :status_code => 500
      }
    when :no_seeders
      {
        :state => :no_seeders,
        :message => "Nothing was thrown to you.",
        :expires => 0,
        :resources => [],
        :status_code => 500
      }
    when :ready
      linked_events = nearby_events
      upload        = linked_events.first.try(:upload)
      
      {
        :state => :ready,
        :message => "Transfering content",
        :expires => 0,
        :resources => (upload ? [upload.uuid] : []),
        :status_code => 200
      }
    end
    
    if result[:state].to_s != state
      
      Event.update_all(
        "state = '#{result[:state].to_s}'",
        ["event_group_id = ?", event_group_id]
      )
    end
    
    result
  end
    
end
