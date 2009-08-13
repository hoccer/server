class GesturesController < ApplicationController
  
  def create
    gesture = Gesture.create_located_gesture(
      params[:gesture], params[:location_id]
    )
    
    render :json => {:uri => upload_url(:id => gesture.upload.checksum)}.to_json
  end
    
end
