import asyncdispatch, json, os, strutils

# Function to handle incoming messages from the server
proc handleMessage(data: JsonNode) {.async.} =
  # Print the message to the console
  echo data

# Connect to the Socket.IO server
var sock = newAsyncSocket(AF_INET, SOCK_STREAM)
await sock.connect(("localhost", 3000))

# Send the handshake message to the server
await sock.write("GET /socket.io/?EIO=3&transport=polling&t=M7VcR5Z HTTP/1.1\r\n" &
                 "Host: localhost:3000\r\n" &
                 "Connection: keep-alive\r\n" &
                 "User-Agent: Nim (https://nim-lang.org)\r\n" &
                 "Accept: */*\r\n" &
                 "\r\n")

# Loop to handle the response from the server
while true:
  # Read the response status line
  var status = await sock.readLine()

  # Read the response headers
  var headers = newTable[string, string]()
  while true:
    var line = await sock.readLine()
    if line.len == 0:
      break
    var parts = line.split(": ")
    headers[parts[0]] = parts[1]

  # Read the response body
  var body = await sock.readString(parseInt(headers["Content-Length"], 10))

  # Parse the response as JSON
  var data = json.parse(body)

  # If the response contains a message, handle it
  if data[0].kind == nkJsonArray and data[0][0].kind == nkInt and data[0][0] == 2:
    spawn handleMessage(data[1])

  # If the response contains an update to the Socket.IO session, store the session ID
  if data[0].kind == nkJsonArray and data[0][0].kind == nkInt and data[0][0] == 4:
    var sid = data[0][1]

# Loop to read messages from the user and send them to the server
while true:
  # Read a message from the user
  var message = readLine(stdin)

  # Send the message to the server
  await sock.write(format("{:x}\r\n", json.stringify([2, message])))
