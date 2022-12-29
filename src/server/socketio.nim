import asyncdispatch, json, os, strutils

# Function to handle incoming Socket.IO connections
proc handleConnection(sock: AsyncSocket) {.async.} =
  # Read the handshake message from the client
  var handshake = await sock.readLine()

  # Extract the Socket.IO session ID from the handshake message
  var sid = handshake.split(" ")[1].split(":")[0]

  # Send the response message to the client to complete the handshake
  await sock.write("HTTP/1.1 200 OK\r\n" &
                   "Content-Type: application/json\r\n" &
                   "Access-Control-Allow-Origin: *\r\n" &
                   "Access-Control-Allow-Credentials: true\r\n" &
                   "Connection: keep-alive\r\n" &
                   "Transfer-Encoding: chunked\r\n" &
                   "\r\n" &
                   "{\"sid\":\"" & sid & "\",\"upgrades\":[],\"pingInterval\":25000,\"pingTimeout\":60000}\r\n")

  # Loop to handle incoming messages from the client
  while true:
    # Read the message length from the client
    var length = await sock.readLine()

    # Read the message from the client
    var message = await sock.readString(parseInt(length, 16))

    # Parse the message as JSON
    var data = json.parse(message)

    # Print the message to the console
    echo data

    # Respond to the client with a message
    await sock.write(format("{:x}\r\n", "Hello, world!"))

# Create a server to listen for incoming connections
var server = newAsyncSocket(AF_INET, SOCK_STREAM)
server.setReuseAddr(true)
server.bindAddr(("localhost", 3000))
server.listen(10)

# Loop to accept incoming connections
while true:
  # Accept an incoming connection
  var sock = await server.accept()

  # Spawn a new task to handle the connection
  spawn handleConnection(sock)
