class AddIndexOnAccessPointSightings < ActiveRecord::Migration
  def self.up
    add_index :access_point_sightings, :bssid
  end

  def self.down
    remove_index :access_point_sightings, :bssid
  end
end
