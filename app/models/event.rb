class Event < ActiveRecord::Base
  GuaranteedRadius = 100
  MaxUncertaintiy  = 5050

  add_geo_foo

  validates_presence_of   :latitude, :longitude

  before_create           :generate_uuid, :verify_lifetime, :set_api_version
  before_save             :calculate_postgis_point

  belongs_to              :event_group
  has_many                :access_point_sightings
  has_one                 :upload

  accepts_nested_attributes_for :access_point_sightings
  
  attr_protected          :api_version

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
      :conditions => ["access_point_sightings.bssid IN (?)", bssids]
    )
  end

  def self.with_type *event_types
    if event_types.length == 1
      scoped( :conditions => { :type => event_types[0] })
    else
      scoped( :conditions => ["type IN (?)", event_types] )
    end
  end

  def self.extract_uploads events
    events_with_upload = events.select do |event|
      event.upload && event.upload.uuid
    end
    
    events_with_upload.map do |event|
      {
        :uri          => event.upload.uuid,
        :content_type => event.upload.attachment.content_type,
        :filename     => event.upload.attachment.original_filename
      }
    end
  end

  def self.somewhere_near lat, lon, accuracy
    boxSize = bbox_size lat, 1.2 * MaxUncertaintiy # paranoia factor 1.2
    point = GeoFoo.as_point(lat, lon)
    scoped(
      :conditions => [
        "ST_DWithin(point, #{point}, #{boxSize}) AND "\
        "ST_Distance_Sphere(point, #{point}) <= ? + least(?, 2*(location_accuracy + ?))",
        GuaranteedRadius,
        MaxUncertaintiy,
        accuracy
      ]
    )
  end

  # Instance Methods

  def latest_in_group
    Event.first(
      :select => "ending_at, event_group_id",
      :conditions => {:event_group_id => event_group_id},
      :order => "ending_at DESC"
    ).ending_at
  end

  def expired?
    latest_in_group < Time.now
  end

  def expires
    ( latest_in_group - Time.now ).to_i
  end

  def bssids
    access_point_sightings.all(:select => :bssid).map(&:bssid)
  end

  def linkable_type
    nil
  end
  
  def legacy?
    api_version == 1
  end
  
  def accuracy
    if location_accuracy && (1200.0 < location_accuracy)
      location_accuracy
    else
      1200.0
    end
  end
  
  def nearby_events custom_options = {}
    options = {
      :starting_at  => starting_at,
      :ending_at    => ending_at,
      :longitude    => longitude,
      :latitude     => latitude,
      :bssids       => bssids,
      :types        => linkable_type,
      :accuracy     => accuracy
    }
    
    options.merge! custom_options
    
    unless bssids.empty?
      via_accesspoints( options ) | via_locations( options )
    else
      via_locations( options )
    end
  end
  
  def via_accesspoints options
    results = Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      with_bssids( options[:bssids] ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])
      
    self.update_attribute(:pairing_mode, 0b10) if 0 < results.size
    results
  end
  
  def via_locations options
    results = Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      somewhere_near( options[:latitude], options[:longitude], options[:accuracy] ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])
      
    update_pairing_mode(0b1) if 0 < results.size
    results
  end
  
  def update_pairing_mode bits
    self.update_attribute( :pairing_mode, (pairing_mode | bits) )
  end
  
  def current_state
    return state.to_sym if state != "waiting"
    
    if collisions?
      :collision
    elsif !expired?
      :waiting
    elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
      :no_peers
    elsif expired? && 0 == number_of_seeders && 0 < number_of_peers
      :no_seeders
    elsif expired? && 0 < number_of_seeders && 0 < number_of_peers
      :ready
    else
      :error
    end
  end
  
  def info
    extend Legacy if legacy?
    info_hash
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
    
    def set_api_version
      self.api_version ||= 2
    end

    def verify_lifetime
      self.starting_at ||= Time.now
      self.ending_at   ||= 7.seconds.from_now
    end

    def associate_with_event_group
      linked_events = nearby_events( :types => [seeder, peer] )

      if linked_events.empty?
        event_group = EventGroup.create
        event_group.events << self
      else
        linked_events.first.event_group.events << self
      end
    end
end

class Drop < Event

  after_create :initialize_upload

  def linkable_type
    "Pick"
  end

  def info_hash
    {
      :state        => "ready",
      :message      => "like state but more verbose",
      :expires      => (Time.now - created_at),
      :upload_uri   => upload.uuid,
      :peers        => nearby_events.size,
      :status_code  => 200
    }
  end

end

class Pick < Event

  def linkable_type
    "Drop"
  end

  def info_hash
    linked_events = nearby_events

    if linked_events.empty?
      {
        :state        => "no_content",
        :message      => "Nothing to pick up from this location",
        :status_code  => 424
      }
    else
      {
        :state        => "ready",
        :message      => "content available for download",
        :uploads      => Event.extract_uploads( linked_events ),
        :peers        => linked_events.size,
        :status_code  => 200
      }
    end
  end

end

class Throw < Event
  include Distribute
  
  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

end

class Catch < Event
  include Distribute

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end

end

class SweepOut < Event
  include Pass
  
  def linkable_type
    peer
  end
  
  after_create :initialize_upload, :associate_with_event_group
end

class SweepIn < Event
  include Pass
  
  def linkable_type
    seeder
  end
  
  after_create :associate_with_event_group
end
