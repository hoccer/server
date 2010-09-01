class AddJoinTableForAccessPointsAndPeers < ActiveRecord::Migration
  def self.up
    create_table :access_points_peers, :id => false do |t|
      t.integer :access_point_id
      t.integer :peer_id
    end
  end
  
  def self.down
    drop_table :access_points_peers
  end
end
