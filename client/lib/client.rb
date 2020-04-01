# frozen_string_literal: true

require 'socket'

waiting_message = 'Write your command'
ip = '127.0.0.1'
port = 9100
socket = TCPSocket.new(ip, port)

while server_welcome = socket.gets
  puts server_welcome
end

puts waiting_message

message = gets
while !message.include? "close"
  socket.write(message)

  #server_response = socket.gets
  #puts server_response
  while line = socket.gets
    puts line
  end

  puts '...'
  puts waiting_message
  message = gets
end

socket.close
