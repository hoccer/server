# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100603102940) do

  create_table "access_point_sightings", :force => true do |t|
    t.string   "bssid"
    t.float    "signal"
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_point_sightings", ["bssid"], :name => "index_access_point_sightings_on_bssid"
  add_index "access_point_sightings", ["event_id"], :name => "index_access_point_sightings_on_event_id"

  create_table "access_points", :force => true do |t|
    t.string   "bssid"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "access_points_peers", :id => false, :force => true do |t|
    t.integer "access_point_id"
    t.integer "peer_id"
  end

  create_table "error_reports", :force => true do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_groups", :force => true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# Could not dump table "events" because of following StandardError
#   Unknown type 'geometry' for column 'point'

  create_table "geometry_columns", :id => false, :force => true do |t|
    t.string  "f_table_catalog",   :limit => 256, :null => false
    t.string  "f_table_schema",    :limit => 256, :null => false
    t.string  "f_table_name",      :limit => 256, :null => false
    t.string  "f_geometry_column", :limit => 256, :null => false
    t.integer "coord_dimension",                  :null => false
    t.integer "srid",                             :null => false
    t.string  "type",              :limit => 30,  :null => false
  end

  create_table "peer_groups", :force => true do |t|
    t.datetime "expires_at"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "peers", :force => true do |t|
    t.string   "uid"
    t.string   "gesture"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "accuracy"
    t.boolean  "seeder",        :default => false
    t.integer  "peer_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "spatial_ref_sys", :id => false, :force => true do |t|
    t.integer "srid",                      :null => false
    t.string  "auth_name", :limit => 256
    t.integer "auth_srid"
    t.string  "srtext",    :limit => 2048
    t.string  "proj4text", :limit => 2048
  end

  create_table "uploads", :force => true do |t|
    t.integer  "event_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "peer_id"
  end

  add_index "uploads", ["event_id"], :name => "index_uploads_on_event_id"
  add_index "uploads", ["uuid"], :name => "index_uploads_on_uuid"

end
