class GesturesController < ApplicationController
  
  def create
    
    gesture = Gesture.new_located_gesture(
      params[:gesture], params[:location_id]
    )
    
    number_of_collisions = Gesture.find_in_range(gesture).length
    
    if !gesture.seed_limit || gesture.seed_limit > number_of_collisions
      gesture.save
      render :json => {:uri => upload_url(:id => gesture.upload.checksum)}.to_json
    else
      render :nothing => true, :status => 403
    end
  end
    
end
