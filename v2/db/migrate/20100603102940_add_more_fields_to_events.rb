class AddMoreFieldsToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :local_ip,          :string
    add_column :events, :network_type,      :string
    add_column :events, :network_operator,  :string
    add_column :events, :model,             :string
    add_column :events, :brand,             :string
    add_column :events, :device,            :string
    add_column :events, :manufacturer,      :string
    add_column :events, :version_sdk,       :string
    add_column :events, :hoccability,       :string
    add_column :events, :timestamp,         :string
    add_column :events, :client_uuid,       :string
  end

  def self.down
    remove_column :events, :local_ip
    remove_column :events, :network_type
    remove_column :events, :network_operator
    remove_column :events, :model
    remove_column :events, :brand
    remove_column :events, :device
    remove_column :events, :manufacturer
    remove_column :events, :version_sdk
    remove_column :events, :hoccability
    remove_column :events, :timestamp
    remove_column :events, :client_uuid
  end
end
