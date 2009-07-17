class LocationsController < ApplicationController
  
  def show
    host = "#{request.protocol}#{request.env["HTTP_HOST"]}"
    
    location = Location.find_by_coordinates(params[:id])
    response = {:files => [location.uploads.last].map{|x| host + x.attachment.url}}.to_json
    render :json => response
  end
  
  def search
    host        = "#{request.protocol}#{request.env["HTTP_HOST"]}"
    coordinats  = Location.parse_coordinates(params[:id])
    options     = coordinats.merge(:gesture => params[:gesture])
    gestures    = Location.find_gestures(options)
    
    response = gestures.inject({}) do |result, gesture|
      key = location_gesture_url(
        :location_id => gesture.location.serialized_coordinates, 
        :id => gesture.id
      )
      
      value = {:uploads => gesture.uploads.map {|u| host + u.attachment.url}}
      
      result[key] = value
      result
    end
    
    
    
    render :json => response
  end
  
end
