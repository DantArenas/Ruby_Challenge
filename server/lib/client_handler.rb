# frozen_string_literal: true

require_relative 'command_handler.rb'

class ClientHandler

  attr_reader :client_socket

  def initialize(args)
    @id = args[:id]
    @client_socket = args[:clientSocket]
    @running = true

    # puts "New Client Handler. Id: #{@id}"
    # Memcached only needed as argumt to initialize command handler
    @memcached = Memcached.new
    @command_handler = CommandHandler.new(@memcached, @client_socket)
  end

  # ----------  RECEVING MESSAGES ----------

  def listen
    begin
      if @running
        message = @client_socket.gets.chomp.split('\r\n')[0]
      end
    rescue
      puts "The client #{@id} has disconnected"
      mensaje = 'close'
    end
  end

  def manage_requests (message)
    # We're just checking the command Handler
    @command_handler.split_line(message)
    # TODO we must check if message has a command
    # if the message is a command, we should send it to command handler.
    # command habdler will decide what to do and manage memcached
  end

# ----------  SENDING MESSAGES ----------

def send (string)
  if @running
    @client_socket.puts string
  end
end

# ----------  CLOSE THIS CLIENT CONNECTION ----------
  def close_connection
    @running = false
    @client_socket.puts 'Clossing Service'
    @client_socket.close
  end

end # Client Handler
