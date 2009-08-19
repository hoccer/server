class CreatePeers < ActiveRecord::Migration
  def self.up
    create_table :peers do |t|
      t.string :uid
      t.string :gesture
      t.float :latitude
      t.float :longitude
      t.float :accuracy
      t.boolean :seeder
      t.integer :peer_group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :peers
  end
end
