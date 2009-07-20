class Location < ActiveRecord::Base
  
  has_many   :gestures
  
  def self.create_from coordinate_string
    
    parameters = parse_coordinates(coordinate_string)
    location = create!(
      :latitude  => parameters[:latitude], 
      :longitude => parameters[:longitude], 
      :accuracy  => parameters[:accuracy]
    )
    
    location
  end
  
  def self.new_from_string coordinate_string
    parameters = parse_coordinates(coordinate_string)
    
    location = new(
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
        parameters[:latitude], parameters[:longitude], parameters[:accuracy]
      ]
    )
  end
  
  def self.parse_coordinates coordinate_string
    coordinates = coordinate_string.gsub(/,/, ".").split(";").map { |s| s.to_f }
    result = {
      :latitude => coordinates[0], 
      :longitude => coordinates[1], 
      :accuracy => coordinates[2]
    }
  end
  
  def serialized_coordinates
    "#{latitude};#{longitude};#{accuracy}".gsub(".", ",")
  end
  
  def public_url
    host = "#{request.protocol}#{request.env["HTTP_HOST"]}"
    "#{host}/locations/#{serialized_coordinates}"
  end
  
  def self.find_gestures options
    Gesture.find_all_by_name(
      Gesture::GESTURES[options[:gesture]],
      :joins => :location,
      :conditions => ["locations.created_at > ? AND " \
                      "locations.latitude between ? AND ? AND "\
                      "locations.longitude between ? AND ?", 
                        10.seconds.ago,
                        options[:latitude]  - 0.01, 
                        options[:latitude]  + 0.01,
                        options[:longitude] - 0.01,
                        options[:longitude] + 0.01
                      ]
    )
    
  end

end
