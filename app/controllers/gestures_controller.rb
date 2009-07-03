class GesturesController < ApplicationController
  
  def create
    location = Location.create_from(params[:location_id])
    location.gesture = Gesture.create(params[:gesture])
    
    response = {:uri => location_url(:id => location.serialized_coordinates)}
    
    render :json => response.to_json
  end
  
end
