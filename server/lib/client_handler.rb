# frozen_string_literal: true

require_relative 'command_handler.rb'

class ClientHandler

  attr_reader :client_socket

  def initialize(args)
    @id = args[:id]
    @client_socket = args[:clientSocket]
    @memcached = args[:memcached]
    @running = true
    # puts "New Client Handler. Id: #{@id}"
    @command_handler = CommandHandler.new(@memcached)
  end

  # ----------  RECEVING MESSAGES ----------

  def listen
    begin
      if @running
        message = @client_socket.gets.chomp.split('\r\n')[0]
      end
    rescue
      puts "The client #{@id} has disconnected"
      mensaje = 'close' # this will trigger the remove client protocol in the server
    end
  end

  def manage_requests (message)
    # We're just checking the command Handler
    response = @command_handler.split_command(message) # It's a commnad_response
    send_response(response)
  end

# ----------  SENDING MESSAGES ----------

  def send(string)
    @client_socket.puts string
  end

  def send_response(response)
    if @running
      if response.cache_result != nil
        ## TODO: Send full response
      else
        @client_socket.puts response.message
      end
    end
  end

# ----------  CLOSE THIS CLIENT CONNECTION ----------
  def close_connection
    @running = false
    @client_socket.puts 'Clossing Service'
    @client_socket.close
  end

end # Client Handler
