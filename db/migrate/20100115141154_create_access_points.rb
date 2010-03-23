class CreateAccessPoints < ActiveRecord::Migration
  def self.up
    create_table :access_points do |t|
      t.string :bssid
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end

  def self.down
    drop_table :access_points
  end
end
