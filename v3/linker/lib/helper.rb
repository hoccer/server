SERVER        = "localhost"
PORT          = 4567

def em_request method, path, content, &block
  http = EM::Protocols::HttpClient.request(
    :host => SERVER,
    :port => PORT,
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

def authorized_request &block

  if ENV["RACK_ENV"] == "production"
    EM.next_tick do
      db          = EM::Mongo::Connection.new.db('hoccer_development')
      collection  = db.collection('accounts')

      collection.first("api_key" => params["apiKey"]) do |account|
        if account.nil?
          ahalt 401
        else
          signature = params.delete("signature")
          uri       = env['REQUEST_URI'].gsub(/\&signature\=.+$/, "")

          digestor = Digest::HMAC.new(account["shared_secret"], Digest::SHA1)
          computed_signature = digestor.base64digest(uri)

          if signature == computed_signature
            block.call( account )
          else
            ahalt 401
          end
        end
      end
    end
  else
    block.call
  end
end
