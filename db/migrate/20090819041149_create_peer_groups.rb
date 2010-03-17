class CreatePeerGroups < ActiveRecord::Migration
  def self.up
    create_table :peer_groups do |t|
      t.datetime :expires_at
      t.string   :type
      t.timestamps
    end
  end

  def self.down
    drop_table :peer_groups
  end
end
