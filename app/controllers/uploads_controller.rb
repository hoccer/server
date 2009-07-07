class UploadsController < ApplicationController
  
  def create
    
    location = Location.find_by_coordinates(params[:location_id])
    
    if location.uploads.create params[:upload]
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 500
    end
  end
  
end
