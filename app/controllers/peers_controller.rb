class PeersController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  
  def create
    bssids_to_access_points
    
    peer = Peer.new( params[:peer] )
    
    if peer.save
      response = { :peer_uri => peer_url(:id => peer.uid),
                   :message => "Searching for partner" }  
      response[:upload_uri] = upload_url(:id => peer.upload.uid) if peer.seeder
      render :json => response.to_json
    else
      render(
        :json => {
          :state => :error, 
          :message => "An error occurred. Please report to hoccer@artcom.de"
        }, 
        :status => 500
      )
    end
      
  end

  def show
    peer        = Peer.find_by_uid(params[:id])
    status      = peer.peer_group.status
    
    unless status[:state] == :waiting
      logger.info peer.peer_group.log_peer_group_info 
    end
    
    # Rewrite Resource Links. There has to be a better way for that like
    # returning the proper urls right from the model, somehow. Can be done
    # later.
    status[:resources]  = status[:resources].map {|u| upload_url(:id => u)}
    status[:message] = "Uploading your content" if peer.seeder and status[:status_code] == 200
    render :json => status.to_json, :status => status[:status_code]
  end
  
  # Rewrites bssid array into nested attributes hash
  def bssids_to_access_points
    return unless params[:peer]
    
    bssids = params[:peer].delete(:bssids)
    
    unless bssids.nil? || bssids.empty?
      access_points = { 
        :access_points_attributes => bssids.map {|bssid| {:bssid => bssid} }
      }
    end
    
    params[:peer].merge!(access_points) if access_points
  end
  
end
