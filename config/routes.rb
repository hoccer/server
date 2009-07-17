ActionController::Routing::Routes.draw do |map|

  map.resources :locations do |location|
	  location.resources :gestures do |gesture|
		  gesture.resource :upload
	  end
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
