class CreateEvents < ActiveRecord::Migration
  def self.up
    
    create_table :events do |t|
      t.float      :longitude
      t.float      :latitude
      t.string     :type
      t.datetime   :starting_at
      t.datetime   :ending_at
      t.string     :uuid
      t.timestamps
    end
    
    table_name = "events"
    self.connection.execute "SELECT AddGeometryColumn('#{table_name}', 'point', #{GeoFoo::Core::SRID}, 'POINT', 2)"
    self.connection.execute "CREATE INDEX #{table_name}_point_index ON #{table_name} USING GIST (point)"
  end

  def self.down
    drop_table :events
  end
end
