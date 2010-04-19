class AddIndexOnUploadsEventIdAndUuid < ActiveRecord::Migration
  def self.up
    add_index :uploads, :uuid
    add_index :uploads, :event_id
  end

  def self.down
    remove_index :uploads, :uuid
    remove_index :uploads, :event_id
  end
end
