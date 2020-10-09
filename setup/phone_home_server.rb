require 'socket'               # Get sockets from stdlib

server = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
  client = server.accept       # Wait for a client to connect
  method, path = client.gets.split                    # In this case, method = "POST" and path = "/"
  headers = {}
  while line = client.gets.split(' ', 2)              # Collect HTTP headers
    break if line[0] == ""                            # Blank line means no more headers
    headers[line[0].chop] = line[1].strip             # Hash headers by type
  end
  data = client.read(headers["Content-Length"].to_i)  # Read the POST data as specified in the header

  puts headers.inspect
  puts "#"*50
  puts data                                           # Do what you want with the POST data
  puts "#"*50

  client.puts(Time.now.ctime)  # Send the time to the client
  client.puts "Closing the connection. Bye!"
  client.close                 # Disconnect from the client
}