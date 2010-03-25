class AddIndicesToEvents < ActiveRecord::Migration
  def self.up
    add_index :events, :event_group_id
    add_index :events, :starting_at
    add_index :events, :ending_at
    add_index :events, :uuid
    add_index :events, :state
    add_index :events, :type
  end

  def self.down
    remove_index :events, :event_group_id
    remove_index :events, :starting_at
    remove_index :events, :ending_at
    remove_index :events, :uuid
    remove_index :events, :state
    remove_index :events, :type
  end
end
