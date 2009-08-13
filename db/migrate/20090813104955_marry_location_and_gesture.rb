class MarryLocationAndGesture < ActiveRecord::Migration
  def self.up
    add_column :gestures, :latitude, :float
    add_column :gestures, :longitude, :float
    add_column :gestures, :accuracy,  :float
  end

  def self.down
    remove_column :gestures, :latitdude
    remove_column :gestures, :longitude
    remove_column :gestures, :accuracy
  end
end
