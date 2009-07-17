class GesturesController < ApplicationController
  
  def create
    location = Location.create_from(params[:location_id])
    
    gesture =  Gesture.create(params[:gesture])
    location.gestures << gesture
    
    if gesture.seeding?
      response = {:uri => location_gesture_url(:id => gesture.id, :location_id => location.serialized_coordinates )}
    else
      response = {:uri => location_url(:id => wait_for_seeder(location))}
    end
    
    render :json => response.to_json
  end
  
  def wait_for_seeder location
    expiration_time = Time.now + 10.seconds
    
    while Time.now < expiration_time
      if seeder = location.find_seeder
        return seeder.serialized_coordinates
      end
    end
    
    return nil
  end
  
end
