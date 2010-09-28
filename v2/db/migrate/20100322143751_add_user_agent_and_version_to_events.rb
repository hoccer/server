class AddUserAgentAndVersionToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :user_agent, :string
    add_column :events, :api_version, :integer
  end

  def self.down
    remove_column :events, :user_agent
    remove_column :events, :api_version
  end
end
