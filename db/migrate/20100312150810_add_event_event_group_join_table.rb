class AddEventEventGroupJoinTable < ActiveRecord::Migration
  def self.up
    create_table :event_groups_events, :id => false do |t|
      t.integer :event_id
      t.integer :event_group_id
    end
  end

  def self.down
    drop_table :event_groups_events
  end
end
