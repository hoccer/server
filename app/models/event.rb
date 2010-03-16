class Event < ActiveRecord::Base
  
  add_geo_foo
  
  validates_presence_of   :latitude, :longitude
  
  before_create           :generate_uuid
  before_save             :calculate_postgis_point
  after_create            :initialize_upload
  
  has_many                :access_point_sightings
  has_and_belongs_to_many :event_groups
  has_one                 :upload
  
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
  
  def self.with_type event_type
    scoped(
      :conditions => {:type => event_type}
    )
  end
  
  # Instance Methods
  
  def bssids
    access_point_sightings.all(:select => :bssid).map(&:bssid)
  end
  
  def linkable_type
    nil
  end
  
  def nearby_events
    via_accesspoints, via_locations = [], []
    
    via_accesspoints = ( Event .
      within_timeframe( starting_at, ending_at ) .
      with_bssids( bssids ) .
      with_type( linkable_type ) .
      scoped(:conditions => ["events.id != ?", self.id])
    )
    
    if via_accesspoints.empty?
      via_locations = ( Event .
        within_timeframe( starting_at, ending_at ) .
        within_radius( latitude, longitude, 100.0 ) .
        with_type( linkable_type ) .
        scoped(:conditions => ["events.id != ?", self.id])
      )
    end
    
    via_accesspoints | via_locations
  end
  
  
  private
  
    def generate_uuid
      self.uuid = UUID.generate(:compact)
    end
  
    def calculate_postgis_point
      self.point = connection.execute(
        "SELECT #{GeoFoo.as_point(latitude, longitude)}"
      )[0]["st_geomfromtext"]
    end
    
    def initialize_upload
      upload = Upload.create :uuid => UUID.generate(:compact), :event_id => id
    end
end

class Drop < Event
  
  after_create :create_event_group
  
  private
  
  def create_event_group
    self.event_groups << Deposit.create
  end
  
end

class Pick < Event
  
  after_create :join_event_group
  
  def linkable_type
    "Drop"
  end
  
  private
  
  def join_event_group
    events = nearby_events
    
    unless events.empty?
      events.first.event_groups.first.events << self
    end
  end
  
end
