def em_request method, path, content, &block
  http = EM::Protocols::HttpClient.request(
    :host => Hoccer.config["grouper_host"],
    :port => Hoccer.config["grouper_port"],
    :verb => method   ||= "GET",
    :request => path  ||= "/",
    :content => content
  )

  http.callback do |response|
    block.call( response )
  end
end

def method_missing symbol, *args, &block
  if [:em_get, :em_post, :em_delete, :em_put].include? symbol
    case symbol
    when :em_get
      em_request "GET", args[0], nil, &block
    when :em_delete
      em_request "DELETE", args[0], nil, &block
    when :em_post
      em_request "POST", *args, &block
    when :em_put
      em_request "PUT", *args, &block
    end
  else
    super symbol, args, &block
  end
end

def halt_with_error code, message = ""
  ahalt(
    code,
    {'Content-Type' => 'application/json' },
    {:error => message}.to_json
  )
end

def protocol_and_host
  scheme = request.env["HTTP_X_FORWARDED_PROTO"] || request.scheme
  "#{scheme}://#{request.host}"
end

def request_uri
  uri_without_signature = env['REQUEST_URI'].gsub(/\&signature\=.+$/, "")

  if env['REQUEST_URI'] =~ /^http\:\/\//
    uri_without_signature
  else
    protocol_and_host + uri_without_signature
  end
end

def authorized_request &block
  if env['HTTP_REFERER']
    referer = env['HTTP_REFERER'].match(/^(https?:\/\/[\d\w\-_.]+)\//)[1]
  end
  
  if ENV["RACK_ENV"] == "production"
    EM.next_tick do

      collection.first("api_key" => params["api_key"]) do |account|
        if account.nil?
          halt_with_error 401, "Invalid API Key"
        else
          signature = params.delete("signature")

          digestor = Digest::HMAC.new( account["shared_secret"], Digest::SHA1 )
          computed_signature = digestor.base64digest( request_uri )
          
          if signature == computed_signature || (referer && account["websites"].include?(referer))
            block.call( account )
          else
            halt_with_error 401, "Invalid Signature"
          end
        end
      end
    end
  else
    block.call
  end
end

private
@@collection = nil;
def collection
  unless @@collection
    puts "creating collection"
    db            = EM::Mongo::Connection.new.db( Hoccer.config["database"] )
    @@collection ||= db.collection('accounts')
  end
  
  @@collection
end