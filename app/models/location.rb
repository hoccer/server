class Location < ActiveRecord::Base
  
  EARTH_RADIUS = 6378100 # in Meters
  
  # named scopes
  
  named_scope :recent, lambda { {:conditions => ["created_at > ?", (5.seconds.ago)]}}
  
  
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
    
    location = self.new parameters
    
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
  
  def self.distance location_a, location_b
    
    distance_latitude   = (location_a.latitude - location_b.latitude).to_rad
    distance_longitude  = (location_a.longitude - location_b.longitude).to_rad
    
    a = (Math.sin(distance_latitude/2) ** 2) + 
        (Math.cos(location_a.latitude.to_rad) * 
        Math.cos(location_b.latitude.to_rad)) * 
        (Math.sin((distance_longitude/2) ** 2))
        
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    distance = EARTH_RADIUS * c
    
  end
  
  def serialized_coordinates
    "#{latitude};#{longitude};#{accuracy}".gsub(".", ",")
  end
  
  def public_url
    host = "#{request.protocol}#{request.env["HTTP_HOST"]}"
    "#{host}/locations/#{serialized_coordinates}"
  end
  
  def self.find_gestures search_location, gesture_name
    
    locations = Location.recent(:include => :gestures).select do |location|

      max_distance  = location.accuracy + search_location.accuracy
      real_distance = Location.distance location, search_location
      logger.info ">> max/real distance: #{max_distance} / #{real_distance}"
      real_distance < max_distance && location.gestures[0].name == gesture_name
      
    end
    
    locations.map {|l| l.gestures[0]}
    
  end

end
