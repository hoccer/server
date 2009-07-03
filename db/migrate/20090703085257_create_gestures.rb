class CreateGestures < ActiveRecord::Migration
  def self.up
    create_table :gestures do |t|
      t.string :name
      t.integer :location_id

      t.timestamps
    end
  end

  def self.down
    drop_table :gestures
  end
end
