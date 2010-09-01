class CreateAccessPointSightings < ActiveRecord::Migration
  def self.up
    create_table :access_point_sightings do |t|
      t.string :bssid
      t.float :signal
      t.integer :event_id

      t.timestamps
    end
  end

  def self.down
    drop_table :access_point_sightings
  end
end
