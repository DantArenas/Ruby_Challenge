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
        message = @client_socket.gets.chomp.split('\r\n')
      end
    rescue
      @running = false
      puts "The client #{@id} has disconnected"
      message = ['close'] # this will trigger the remove client protocol in the server
    end
  end

  def manage_requests (message)
    # We're just checking the command Handler
    parsed_command = @command_handler.split_command(message[0]) # It's a commnad_response
    if parsed_command.success

      # Add data if is a storage request
      if @command_handler.is_storage?(parsed_command.args[:command])
        data = if message.length >= 2
               message[1]
             else
               @client_socket.puts('SEND DATA')
               get_missing_data(@client_socket, parsed_command.args[:bytes])
             end
        parsed_command.add_data(data)
      end

      response = @command_handler.manage_request(parsed_command.args)
      send_response(response) if response != nil
    else
      send_response(parsed_command)
    end
  end # listen

  def get_missing_data(socket, length)
    data = socket.recv(length + 2)
    data[0..-2] # delete the car trailing \r\n
  end

# ----------  SENDING MESSAGES ----------

  def send(string)
    @client_socket.puts string
  end

  def send_response(response)
    if @running
      @client_socket.puts response.message
    end
  end

# ----------  CLOSE THIS CLIENT CONNECTION ----------
  def close_connection
    @running = false
    @client_socket.puts 'Clossing Service'
    @client_socket.close
  end

end # Client Handler
