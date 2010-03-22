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
end