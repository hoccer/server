module Share
  
  def collisions?
    (1 < number_of_peers) || (1 < number_of_seeders)
  end

  def number_of_peers
    event_group.events.with_type( peer ).count
  end

  def number_of_seeders
    event_group.events.with_type( seeder ).count
  end
  
end