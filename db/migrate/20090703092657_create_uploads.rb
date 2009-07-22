class CreateUploads < ActiveRecord::Migration
  def self.up
    create_table :uploads do |t|
      t.integer   :gesture_id
      t.string    :attachment_file_name
      t.string    :attachment_content_type
      t.integer   :attachment_file_size
      t.datetime  :attachment_uploaded_at
      t.string    :checksum
      t.integer   :download_counter,        :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :uploads
  end
end
