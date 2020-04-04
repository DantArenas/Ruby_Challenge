# frozen_string_literal: true

# Meta Commands are to include yet

class CommandHandler

  def initialize(memcached, client_socket)
    @cache = memcached
    @client_socket = client_socket
  end

 # Here we verify the command structure
  def split_line(command_line)
    parts = command_line.split("\s")

    unless valid_command?(parts[0])
      @client_socket.puts "Received: #{command_line}"
    end
  end

  # Here we'll validate the incomming commands
  def valid_command? (command)
    valid_command = false
    if command.eql? 'hello'
      valid_command = true
      @client_socket.puts "Server Says: Hey There! How are you?"
    end
    valid_command
  end
end
