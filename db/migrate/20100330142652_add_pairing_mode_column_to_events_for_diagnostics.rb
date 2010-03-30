class AddPairingModeColumnToEventsForDiagnostics < ActiveRecord::Migration
  def self.up
    add_column :events, :pairing_mode, :integer
  end

  def self.down
    remove_column :events, :pairing_mode
  end
end
