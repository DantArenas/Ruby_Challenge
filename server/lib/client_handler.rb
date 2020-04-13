# frozen_string_literal: true

require_relative 'command_handler.rb'

class ClientHandler

  attr_reader :client_socket, :id

  def initialize(args)
    # this id isn't specified in the protocol, but it's
    # useful as a reference
    @@id = args[:id]
    @client_socket = args[:clientSocket]
    @memcached = args[:memcached]
    @running = true
    # puts "New Client Handler. Id: #{@id}"
    @command_handler = CommandHandler.new(@memcached)
  end

  # ----------  RECEVING MESSAGES ----------

  # waits for the client to send a request
  def listen
    begin
      if @running
        # We assume that th command line goes like:
        # command <command_data> \r\nDATA\r\n
        message = @client_socket.gets.chomp.split('\r\n')
      end
    rescue # if there is a problem with the client connections, it is closed
      @running = false
      puts "The client #{@@id} has disconnected"
      message = ['close'] # this will trigger the remove client protocol in the server
    end
  end

  def manage_requests (message)
    # We're just checking the command Handler
    parsed_command = @command_handler.split_command(message[0])
    # parsed_command it's a commnad_response class object

    if parsed_command.success # if the command can be interpreted

      # Add data if is a storage request
      if @command_handler.is_storage?(parsed_command.args[:command])
        data = if message.length >= 2 # data is already sent
               message[1] # we assume data is contained betwen '\r\nDATA\r\n'
             elsif parsed_command.args[:command] != 'incr' && parsed_command.args[:command] != 'decr'
               # data is missing, ask the client to send the data
               @client_socket.puts('SEND DATA')
               get_missing_data(@client_socket, parsed_command.args[:bytes])
             end
        parsed_command.add_data(data) # add data to args before passing to command_handler
      end

      # the method 'manage_request' manages both 'storage' and 'retrieval' requests
      response = @command_handler.manage_request(parsed_command.args)
      # In this point, if response == nil, is becaused the client specified
      # noreply when sending the command. Else, no matter if the operation was or not
      # successful, the server sends a message qith the response
      send_response(response) if response != nil
    else # the command couldn't be splitted or interpreted
      # sends the client a message informing the line wasn't a valid command
      response = @command_handler.manage_request(parsed_command.args)
      send_response(response)
    end
  end # listen

  # when the command line was accepted but data is missing,
  # waits in the socket until client send it
  def get_missing_data(socket, length)
    ## TODO: validate the lengths sent by the user are accurate
    data = socket.recv(length + 2)
    data[0..-2] # delete the car trailing \r\n
  end

# ----------  SENDING MESSAGES ----------

  # This method sends the specific string
  def send(string)
    @client_socket.puts string
  end

  # This method sends the message of the response, not the objetc
  def send_response(response)
    if @running
      @client_socket.puts response.message
    end
  end

  # if we want to send the data as an object, we can use JSon
  def send_json(response)
    ## TODO: Parse the response into a JSon object to send it through the socket
  end

# ----------  CLOSE THIS CLIENT CONNECTION ----------
  def close_connection
    begin
      @client_socket.puts 'Clossing Service'
      @client_socket.close # and so, the service ends
    rescue
      # client was not available, already closed
    end
  end

end # Client Handler
