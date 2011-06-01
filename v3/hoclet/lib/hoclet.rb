require 'mongoid'

class Hoclet
  include Mongoid::Document
  
  field :address
  field :owner
  field :content
  field :previous_content
end