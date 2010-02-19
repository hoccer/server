class RenameUploadedAtToUpdatedAt < ActiveRecord::Migration
  def self.up
    rename_column :uploads, :attachment_uploaded_at, :attachment_updated_at
  end

  def self.down
    rename_column :uploads, :attachment_updated_at, :attachment_uploaded_at
  end
end
