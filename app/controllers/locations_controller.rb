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
    
    gestures    = get_gestures(options)
    counter     = 0
    
    while gestures.empty? && counter < 5
      sleep(1)
      gestures = get_gestures(options)
      counter += 1
    end
    
    response    = {
      :uploads => gestures.map {|g| "#{host}/uploads/#{g.upload.checksum}"}
    }
    
    render :json => response
  end
  
  
  def get_gestures options
    gestures = Location.find_gestures(options)
  end
end
