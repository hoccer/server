class Gesture < ActiveRecord::Base
  
  belongs_to :location
  has_one :upload

end