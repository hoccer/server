class AddDefaultStateForEvents < ActiveRecord::Migration
  def self.up
    change_column :events, :state, :string, :default => "waiting"
  end

  def self.down
    change_column :events, :state, :string, :default => nil
  end
end
