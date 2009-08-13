require 'sha1'

class Gesture < ActiveRecord::Base
  
  EARTH_RADIUS = 6367516 # in Meters
  
  # named scopes
  
  named_scope :recent, lambda { {:conditions => ["created_at > ?", (5.seconds.ago)]}}
  
  
  belongs_to :location
  has_one :upload
  
  
  after_create :initialize_upload
  
  def self.parse_coordinates coordinate_string
    coordinates = coordinate_string.gsub(/,/, ".").split(";").map { |s| s.to_f }
    result = {
      :latitude => coordinates[0], 
      :longitude => coordinates[1], 
      :accuracy => coordinates[2]
    }
  end

  def self.create_located_gesture gesture, location_string
    options = parse_coordinates(location_string).merge(gesture)
    gesture = Gesture.create options
  end
  
  def self.new_located_gesture gesture, location_string
    options = parse_coordinates(location_string).merge(:name => gesture)
    gesture = Gesture.new options
  end
  
  def self.find_seeder search_gesture
    
    gestures = Gesture.recent.select do |gesture|
      max_distance  = gesture.accuracy + search_gesture.accuracy
      real_distance = Gesture.distance gesture, search_gesture
      logger.info ">> max/real distance: #{max_distance} / #{real_distance}"
      real_distance < max_distance && gesture.name == search_gesture.name
    end
    
    gestures
    
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

  private
  
    def initialize_upload
      sha = SHA1.new(Time.now.to_s).to_s
      
      upload = Upload.create(:checksum => sha)
      self.upload = upload
      upload.save
    end
    
    
end