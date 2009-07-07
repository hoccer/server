class Location < ActiveRecord::Base
  
  has_one   :gesture
  has_many  :uploads
  
  def self.create_from coordinate_string
    
    parameters = parse_coordinates(coordinate_string)
    
    location = create(
      :latitude  => parameters[0], 
      :longitude => parameters[1], 
      :accuracy  => parameters[2]
    )
    
    location
  end
  
  def self.find_by_coordinates coordinate_string
    
    parameters = parse_coordinates(coordinate_string)
    
    Location.find(
      :first, 
      :conditions => [
        "latitude = ? AND longitude = ? AND accuracy = ?",
        parameters[0], parameters[1], parameters[2]
      ]
    )
  end
  
  def self.parse_coordinates coordinate_string
    coordinate_string.gsub(/,/, ".").split(";").map { |s| s.to_f }
  end
  
  def serialized_coordinates
    "#{latitude};#{longitude};#{accuracy}".gsub(".", ",")
  end
  
  def find_seeder
    Gesture.find_by_name(
      Gesture::GESTURES[gesture.name],
      :joins => :location,
      :conditions => ["locations.created_at > ? AND " \
                      "locations.latitude between ? AND ? AND "\
                      "locations.longitude between ? AND ?", 
                        10.seconds.ago,
                        latitude - 0.01, 
                        latitude + 0.01,
                        longitude - 0.01,
                        longitude + 0.01
                      ]
    ).location
    
  end
  
end
