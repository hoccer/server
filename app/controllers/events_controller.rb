class EventsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def index
  end

  def create
    convert_bssid_params
    
    event_type  = params[:event].delete(:type)
    base        = Event.const_get(event_type.titlecase)
    
    event = base.new params[:event]
    
    if event.save
      redirect_to event_path(event), :status => 303
    else
      render :nothing => true, :status => 404
    end
  end

  def show
  end
  
  private
  
    # Rewrites bssid array into nested attributes hash
    def convert_bssid_params
      return unless params[:event] && params[:event][:bssids]
      
      bssids = params[:event].delete(:bssids).split(",").flatten
      
      unless bssids.nil? || bssids.empty?
        access_points = {
          :access_point_sightings_attributes => bssids.map do |bssid|
            {:bssid => bssid }
          end
        }
      end
      
      params[:event].merge!(access_points) if access_points
    end

end
