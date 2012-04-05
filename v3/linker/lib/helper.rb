# passing requests to the grouper

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

# passing requests to the hoclet server

def hoclet_request method, path, content, &block

  # get configuration
  host = Hoccer.config["hoclet_host"]
  port = Hoccer.config["hoclet_port"]

  # bail out if hoclets are disabled
  if host.nil? || host == "" || port.nil? || port == ""
    return
  end

  # compose request to hoclet server
  http = EM::Protocols::HttpClient.request(
    :host => host,
    :port => port,
    :verb => method ||= "POST",
    :request => path ||= "/",
    :content => content
  )

  # log the request
  puts "request to hoclet server: #{http.method} #{http.request} #{http.content}"

  # when done...
  http.callback do |response|

    # log the response
    code = response[:code]
    content = response[:content]
    puts "response from hoclet server: #{code} #{content}"

    # call back if required
    unless block.nil?
      block.call( response )
    end
  end
end

# halt with error

def halt_with_error code, message = ""
  ahalt(
    code,
    {'Content-Type' => 'application/json' },
    {:error => message}.to_json
  )
end

# helper functions for checking signature

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

# check for valid api key and signature before executing block

def authorized_request &block
  referrer = env['HTTP_ORIGIN']

  if ENV["RACK_ENV"] == "production" # production only
    EM.next_tick do
      $db         ||= EM::Mongo::Connection.new.db( Hoccer.config["database"] )
      collection  = $db.collection('accounts')

      collection.first("api_key" => params["api_key"]) do |account|
        if account.nil?
          halt_with_error 401, "Invalid API Key"
        else
          signature = params.delete("signature")

          digestor = Digest::HMAC.new( account["shared_secret"], Digest::SHA1 )
          computed_signature = digestor.base64digest( request_uri )

          if signature == computed_signature || (referrer && account["websites"].include?(referrer))
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

# log action in database
# defined identically in client.rb, remove one

def log_action action_name, api_key
  EM.next_tick do
    $db         ||= EM::Mongo::Connection.new.db( Hoccer.config["database"] )
    collection  = $db.collection('api_stats')
    doc = {
      :api_key    => api_key,
      :action     => action_name,
      :timestamp  => Time.now
    }
    collection.insert( doc )
  end
end

def log_hoc options
  $db_stats     ||= EM::Mongo::Connection.new.db( Hoccer.config["stats"] )
  collection  = $db_stats.collection('hoc_stats')
  doc = options.merge({:timestamp => Time.now})

  collection.insert( doc )
end

# write in log with timestamp

def logs message
  puts "#{Time.now}: #{message}"
end
