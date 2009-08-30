require "sha1"

class Peer < ActiveRecord::Base
  
  # Constants
  EARTH_RADIUS    = 6367516 # in Meters
  PEERING_TIMEOUT = 7.seconds
  
  # Filters
  before_create :generate_uid
  after_create  :associate_with_peer_group, :initialize_upload
  
  # Associations
  belongs_to  :peer_group
  has_one     :upload
  
  # Named Scopes
  named_scope :recent, lambda { {:conditions => ["created_at > ?", (10.seconds.ago)]}}
  
  # Validations
  validates_inclusion_of :gesture, :in => %w(pass distribute exchange)
  
  # Class Methods
  
  # Returns all peers in range of given peer that have the same gesture.
  def self.find_all_in_range_of search_peer
    peers = Peer.recent.select do |peer|
      max_distance  = peer.radius + search_peer.radius
      real_distance = Peer.distance( peer, search_peer )
      logger.info ">> max/real distance: #{max_distance} / #{real_distance}"
      real_distance < max_distance && peer.gesture == search_peer.gesture
    end
    
    peers - [search_peer]
  end
  
  # Only returns the first peer in range
  def self.find_in_range_of search_peer
    find_all_in_range_of(search_peer).first
  end
  
  # Calculates the distance in meters between two peers
  def self.distance peer_a, peer_b
    distance_latitude   = (peer_a.latitude - peer_b.latitude).to_rad
    distance_longitude  = (peer_a.longitude - peer_b.longitude).to_rad
    
    a = (Math.sin(distance_latitude/2) ** 2) + 
        (Math.cos(peer_a.latitude.to_rad) * 
        Math.cos(peer_b.latitude.to_rad)) * 
        (Math.sin((distance_longitude/2) ** 2))
        
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    distance = EARTH_RADIUS * c
  end
  
  # Instance Methods
  
  def serialize_coordinates
    "#{self.latitude};#{self.longitude};#{self.accuracy}"
  end
  
  def radius
    return 100 if accuracy < 100
    accuracy
  end
  
  # Checks if a given peer is the first seeder in its peer group
  def first_seeder?
    number_of_seeders_in_peer_group = self.peer_group.peers.find(
      :all, :conditions => {:seeder => true}
    ).count
    
    self.seeder && number_of_seeders_in_peer_group == 1
  end
  
  # Private Methods
  
  private
    
    def generate_uid
      self.uid = SHA1.new( 
        (latitude+longitude+accuracy).to_s + Time.now.to_s 
      ).to_s
    end
    
    # Searches for existing peers in the range of a given peer. If peers are in 
    # range that match the requested gesture, the new peer is added to the peer 
    # group of the existing peers.
    #
    # If no peers are found in range, a new peer group is created and the new 
    # peer is associated to it.
    def associate_with_peer_group
      peer = Peer.find_in_range_of(self)
      
      if peer && !peer.peer_group.expired?
        peer_group = peer.peer_group
        peer_group.peers << self
        update_expiration_time if self.first_seeder?
      else
        PeerGroup
        peer_group = self.gesture.titlecase.constantize.create
        peer_group.peers << self
        update_expiration_time
      end
    end
    
    # Set a new expiration time on the peers peer group
    def update_expiration_time
      self.peer_group.update_attributes(
        :expires_at => self.created_at + PEERING_TIMEOUT
      )
    end
    
    # Create empty Upload placeholder object and associate it to the peer
    def initialize_upload
      if seeder
        sha = SHA1.new(Time.now.to_s).to_s
        
        upload = Upload.create(:uid => sha)
        self.upload = upload
        upload.save
      end
    end
end
