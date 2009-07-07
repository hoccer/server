class Gesture < ActiveRecord::Base
  
  belongs_to :location
  
  GESTURES = {
    "catch" => "throw"
  }
  
  def seeding?
    GESTURES.values.include?(name)
  end
end