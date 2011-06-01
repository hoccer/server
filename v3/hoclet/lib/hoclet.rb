require 'mongoid'

class Hoclet
  include Mongoid::Document
  
  field :address
  field :owner
  field :content
  field :previous_content
  
  def self.find_by_address_or_create(address, client) 
    hoclet  = Hoclet.where(
      :address => address, 
      :owner => client
    ).first

    if (hoclet.nil?)
      hoclet = Hoclet.new(
        :address => address, 
        :owner => client
    )
    end
    
    hoclet
  end
  
end