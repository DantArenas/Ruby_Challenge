# frozen_string_literal: true

require 'socket'
require 'objspace'

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

  # -------------- SEND MESSAGES TO SERVER--------------

  def send_connection_request
    begin
      Thread.new do
        loop do
          message = $stdin.gets.chomp

          if message == 'add'
            line = 'add 12345 0 60 19 noreplay'
            puts "shortcut ussed... sending: #{line} "
            @socket.puts line
          elsif message == 'tigres'
            @socket.puts 'Tres tristes tigres'
          elsif message == 'cas'
            line = 'cas 12345 0 180 15 321 noreplay'
            print "shortcut ussed... sending: #{line} "
            @socket.puts line
          else
            @socket.puts message
          end
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  # ------------ RECEIVE MESSAGES FROM SERVER ------------

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
    if message.include? 'SEND DATA'
      puts "Storage command accpeted. To continue #{message}"
    elsif message.include? 'Clossing'
      close_client
    elsif message.include? 'Server:'
      puts message
    elsif message.include? 'Server Says:'
      puts message
      puts "You answered: I'm fine, thanks! How are you?"
      @socket.puts "I'm fine, thanks! How are you?"
    else
      puts message
      puts 'Write your command'
    end
  end

  # ------------ CLOSE CONNECTION WITH SERVER ------------

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

=begin
    line = 'Tres tristes tigres'
    data = ["Tres tristes tigres", "comen trigo en el trigal"]
    data_size = ObjectSpace.memsize_of(data)

    def array_bytesize(array)
      byte_size = 0
      array.each do |string|
        byte_size += string.bytesize if (string != nil && string != "")
      end
      byte_size
    end

    byte_size = array_bytesize(data)

    puts "data obj size = #{data_size} vs bytes size = #{byte_size}"
    puts "tigres size = #{line.bytesize}"
=end

socket = TCPSocket.open('localhost', 8080)
Client.new(socket)
