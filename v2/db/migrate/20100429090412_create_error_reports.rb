class CreateErrorReports < ActiveRecord::Migration
  def self.up
    create_table :error_reports do |t|
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :error_reports
  end
end
