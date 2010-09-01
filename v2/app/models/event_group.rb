class EventGroup < ActiveRecord::Base
  
  has_many :events, :dependent => :destroy
  
end

class Deposit < EventGroup
  
end