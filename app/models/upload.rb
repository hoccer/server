class Upload < ActiveRecord::Base
  
  belongs_to        :gesture
  has_attached_file :attachment
  
end
