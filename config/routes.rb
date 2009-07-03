ActionController::Routing::Routes.draw do |map|

  map.resources :locations do |location|
    location.resource :gesture
    location.resource :uploads
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
