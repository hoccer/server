require 'mongoid'
require 'digest/sha1'

module Hoccer
  class Lookup
  include Mongoid::Document

    # find hash for uuid
  
    def self.lookup_uuid id 
      lookup = Lookup.where(:uuid => id).first
      if lookup.nil? 
        hash = Digest::SHA1.hexdigest(id)
        lookup = Lookup.new(:uuid => id, :hash => hash)
        lookup.save
      end
    
      lookup[:hash]
    end

    # find uuid for hash
  
    def self.reverse_lookup hash
      results = Lookup.where(:hash => hash)
      if results.empty?
        ""
      else
        results.first[:uuid]
      end
    end
  end
end
