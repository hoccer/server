module Paperclip
  
  class Vcard < Processor
    def intialize file, options = {}, attachment = nil
      @file = file
      @attachment = attachment
    end

    def make
      mime_type = MIME::Types.type_for(@attachment.original_filename).to_s
      output    = Tempfile.new(@attachment.original_filename)
      
      if mime_type =~ /vcard/
        vcard = @file.read
        newlines = vcard.scan(/\n/)
        carriage_returns = vcard.scan(/\r\n/)
        
        if carriage_returns.empty? && !newlines.empty?
          corrected_vcard = vcard.gsub(/\n/, "\r\n")
          output << corrected_vcard
        else
          output << vcard
        end
      else
        output << @file.read
      end
      
      output
    end
  end  
end