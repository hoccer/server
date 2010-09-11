require 'net/http'
require 'json'


server = "127.0.0.1"
port   = "9292"

client_1_url = ""

Net::HTTP.start(server, port) {|http|
  response = http.request_post "/clients", ""
  client_1_url = response.header["Location"]
}

client_2_url = ""

Net::HTTP.start(server, port) {|http|
  response = http.request_post "/clients", ""
  client_2_url = response.header["Location"]
}

payload = {:gps => {:longitude => 11, :latitude => 12}}.to_json

Net::HTTP.start(server, port) {|http|
  response = http.request_put "#{client_1_url}/environment", payload
  puts response
}
Net::HTTP.start(server, port) {|http|
  response = http.request_put "#{client_2_url}/environment", payload
  puts response
}



shareload = {:inline => "hallo robert"}.to_json
client_1_action_url = ""
Net::HTTP.start(server, port) {|http|
  response = http.request_post "#{client_1_url}/action/distribute", shareload
  client_1_action_url = response.header["Location"]
}
t1_response = ""
t1 = Thread.new do
  Net::HTTP.start(server, port) {|http|
    t1_response = http.get( "#{client_1_url}/action/distribute" )
    puts "OhHAi " + response.body
  }
end


t2 = Thread.new do
  Net::HTTP.start(server, port) {|http|
    t2_response = http.get( "#{client_2_url}/action/distribute" )
    puts "OhHAi " + t2_response.body
  }
end

sleep(0.2)
puts "hello"



__END__
Net::HTTP.start(server, port) {|http|
  response = http.post ""
  puts response.body
}

