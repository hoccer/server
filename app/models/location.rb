class Location < ActiveRecord::Base
  
  has_one   :gesture
  has_many  :upload
  
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
  
end
