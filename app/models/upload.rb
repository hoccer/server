class Upload < ActiveRecord::Base
  
  belongs_to        :location
  has_attached_file :attachment
  
end
