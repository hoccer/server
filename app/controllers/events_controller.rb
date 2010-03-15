class EventsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def index
  end

  def create
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

end
