class AddLocationAccuracyToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :location_accuracy, :float
  end

  def self.down
    remove_column :events, :location_accuracy
  end
end
