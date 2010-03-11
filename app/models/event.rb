class Event < ActiveRecord::Base
  
  add_geo_foo
  
  validates_presence_of :latitude, :longitude
  
  before_save :calculate_postgis_point
  
  has_many :access_point_sightings
  
  accepts_nested_attributes_for :access_point_sightings
  
  # Class Methods
  
  def self.within_timeframe starting_at, ending_at
    scoped(
      :conditions => [
        "(events.starting_at, events.ending_at) OVERLAPS (timestamp ?, timestamp ?)",
        starting_at, ending_at
      ]
    )
  end
  
  def self.with_bssids bssids
    scoped(
      :joins => :access_point_sightings,
      :conditions => ["access_point_sightings.bssid IN (?)", bssids.join(",")]
    )
  end
  
  # Instance Methods
  
  def bssids
    access_point_sightings.all(:select => :bssid).map(&:bssid)
  end
  
  def nearby_events
    via_accesspoints, via_locations = [], []
    
    via_accesspoints = Event.within_timeframe(
      starting_at, ending_at
    ).with_bssids(
      bssids
    ).scoped(:conditions => ["events.id != ?", self.id])
    
    if via_accesspoints.empty?
      via_locations = Event.within_timeframe(
        starting_at, ending_at
      ).within_radius(
        latitude, longitude, 100.0
      ).scoped(:conditions => ["events.id != ?", self.id])
    end
    
    via_accesspoints | via_locations
  end
  
  
  private
  
    def calculate_postgis_point
      self.point = connection.execute(
        "SELECT #{GeoFoo::Core.as_point(latitude, longitude)}"
      )[0]["st_geomfromtext"]
    end
end

class Drop < Event
  
end

class Pick < Event
  
end