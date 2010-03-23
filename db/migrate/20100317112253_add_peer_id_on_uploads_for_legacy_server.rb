class AddPeerIdOnUploadsForLegacyServer < ActiveRecord::Migration
  def self.up
    add_column :uploads, :peer_id, :integer
  end

  def self.down
    remove_column :uploads, :peer_id
  end
end
