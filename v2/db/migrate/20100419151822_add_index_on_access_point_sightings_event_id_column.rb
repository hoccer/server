class AddIndexOnAccessPointSightingsEventIdColumn < ActiveRecord::Migration
  def self.up
    add_index :access_point_sightings, :event_id
  end

  def self.down
    remove_index :access_point_sightings, :event_id
  end
end
