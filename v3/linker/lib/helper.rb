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
      puts args.inspect             
      em_request "PUT", *args, &block
    end
  else
    super symbol, args
  end
  
end