class PeersController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  
  def create
    peer = Peer.create params[:peer]
    
    if peer
      response = { :peer_uri => peer_url(:id => peer.uid),
                   :message => "Building group" }  
      response[:upload_uri] = upload_url(:id => peer.upload.uid) if peer.seeder
      render :json => response.to_json
    else
      render :json => {:state => :error}, :status => 500
    end
      
  end

  def show
    peer        = Peer.find_by_uid(params[:id])
    status      = peer.peer_group.status
    
    log_peer_group_info(peer, status) unless status[:state] == :waiting
    
    # Rewrite Resource Links. There has to be a better way for that like
    # returning the proper urls right from the model, somehow. Can be done
    # later.
    status[:resources]  = status[:resources].map {|u| upload_url(:id => u)}
    render :json => status.to_json, :status => status[:status_code]
  end

  private
    def log_peer_group_info peer, status_hash
      peer_group  = peer.peer_group
      logger.info ">>>>>" \
        "peer_group_id:#{peer_group.id} " \
        "state:#{status_hash[:state]} " \
        "peers:#{peer_group.number_of_peers} " \
        "seeders:#{peer_group.number_of_seeders} " \
        "gesture:#{peer_group.class.to_s} " \
        "locations:#{peer_group.peers.map {|x| x.serialize_coordinates}.join("/")}"
    end
end
