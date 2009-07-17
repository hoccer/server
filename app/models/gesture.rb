class Gesture < ActiveRecord::Base
  
  belongs_to :location
  has_many :uploads
  
  GESTURES = {
    "catch" => "throw"
  }
  
  def seeding?
    GESTURES.values.include?(name)
  end
end