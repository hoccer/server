class EventGroup < ActiveRecord::Base
  
  has_many :events
  
end

class Deposit < EventGroup
  
end