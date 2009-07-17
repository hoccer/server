class UploadsController < ApplicationController
  
  def create
    
    gesture = Gesture.find(params[:gesture_id])
    
    if gesture.uploads.create params[:upload]
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 500
    end
  end
  
end
