# frozen_string_literal: true

require 'socket'

class Client

  def initialize(socket)
    @socket = socket

    @send_connection_request = send_connection_request
    @listen_server = listen_server
    @send_connection_request.join
    @listen_server.join
  end

  trap 'SIGINT' do
    print "Something went wong... Connection Closed! :'C"
    exit 100 # Bad Way
  end

  def send_connection_request
    begin
      Thread.new do
        loop do
          message = $stdin.gets.chomp
          @socket.puts message
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  def listen_server
    begin
      Thread.new do
        loop do
          server_response = @socket.gets
          if server_response != nil
            handle_message(server_response.chomp)
          end
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  def handle_message(message)
    if message.include? "Clossing"
      close_client
    elsif message.include? "Server:"
      puts message
    else
      puts message
      puts 'Write your command'
    end
  end

  def close_client
    print 'Clossing Connection... '
    @socket.close
    sleep(1) # just to add some drama effect
    puts 'Connection Closed! :)'
    exit 0
  end
end

# ===================================================
# ===           HERE WE LAUNCH THE CLIENT         ===
# ===================================================

socket = TCPSocket.open('localhost', 8080)
Client.new(socket)
