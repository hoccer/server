require "sha1"

class Peer < ActiveRecord::Base
  
  EARTH_RADIUS = 6367516 # in Meters
  
  before_create :generate_uid
  after_create  :associate_with_peer_group, :initialize_upload
  
  belongs_to  :peer_group
  has_one     :upload
  
  # named scopes
  named_scope :recent, lambda { {:conditions => ["created_at > ?", (10.seconds.ago)]}}
  
  validates_inclusion_of :gesture, :in => %w(pass distribute exchange)
  
  
  def self.create_from_params params
    options = {
      :gesture  => params[:gesture],
      :seeder   => (params[:role] == "seeder") 
    }
    coordinates = Peer.parse_coordinates( params[:id] )
    create options.merge(coordinates)
  end
  
  def self.parse_coordinates coordinate_string
    coordinates = coordinate_string.gsub(/,/, ".").split(";").map { |s| s.to_f }
    {
      :latitude => coordinates[0], 
      :longitude => coordinates[1], 
      :accuracy => coordinates[2]
    }
  end
  
  def self.find_all_in_range_of search_peer
    peers = Peer.recent.select do |peer|
      max_distance  = peer.accuracy + search_peer.accuracy
      real_distance = Peer.distance( peer, search_peer )
      logger.info ">> max/real distance: #{max_distance} / #{real_distance}"
      real_distance < max_distance && peer.gesture == search_peer.gesture
    end
    
    peers - [search_peer]
  end
  
  def self.find_in_range_of search_peer
    find_all_in_range_of(search_peer).first
  end
  
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
  
  def first_seeder?
    number_of_seeders_in_peer_group = self.peer_group.peers.find(
      :all, :conditions => {:seeder => true}
    ).count
    
    self.seeder && number_of_seeders_in_peer_group == 1
  end
  
  
  
  private
  
    def generate_uid
      self.uid = SHA1.new( 
        (latitude+longitude+accuracy).to_s + Time.now.to_s 
      ).to_s
    end
    
    def associate_with_peer_group
      peer = Peer.find_in_range_of(self)
      
      if peer && !peer.peer_group.expired?
        peer_group = peer.peer_group
        peer_group.peers << self
        update_expiration_time if self.first_seeder?
      else
        peer_group = self.gesture.titlecase.constantize.create
        peer_group.peers << self
        update_expiration_time
      end
    end
    
    def update_expiration_time
      self.peer_group.update_attributes(
        :expires_at => self.created_at + 10.seconds
      )
    end
    
    def initialize_upload
      if seeder
        sha = SHA1.new(Time.now.to_s).to_s
        
        upload = Upload.create(:uid => sha)
        self.upload = upload
        upload.save
      end
    end
end
