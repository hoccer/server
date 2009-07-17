ActionController::Routing::Routes.draw do |map|

  map.resources :locations, :member => {:search => :get} do |location|
	  location.resources :gestures do |gesture|
		  gesture.resources :uploads
	  end
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
