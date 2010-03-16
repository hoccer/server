class Upload < ActiveRecord::Base
  
  belongs_to :event
  
  has_attached_file :attachment
  
end
