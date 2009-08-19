class PeersController < ApplicationController
  
  def create
    peer = Peer.create_from_params params
    
    if peer
      render :json => {
        :peer_uri   => peer_url(:id => peer.uid),
        :upload_uri => upload_url(:id => peer.upload.uid)
      }.to_json
    else
      render :json => {:state => :error}, :status => 500
    end
      
  end

  def show
    peer    = Peer.find_by_uid(params[:id])
    status  = peer.peer_group.status
    status[:resources]  = status[:resources].map {|u| upload_url(:id => u)}
    render :json => status.to_json, :status => status[:status_code]
  end

end
