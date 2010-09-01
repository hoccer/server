class ChangeUserAgentColumnFromVarcharToText < ActiveRecord::Migration
  def self.up
    change_column :events, :user_agent, :text
  end

  def self.down
    change_column :events, :user_agent, :string
  end
end
