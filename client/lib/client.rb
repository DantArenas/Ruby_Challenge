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
            @socket.puts use_shortcut('add 12345 0 60 19 noreplay')
          elsif message == 'cas'
            @socket.puts use_shortcut('cas 12345 0 180 15 321 noreplay')
          elsif message == 'tigres'
              @socket.puts use_shortcut('Tres tristes tigres')
          elsif message == 'multi'
            @socket.puts use_shortcut('add 123 0 60 19 \r\nHabia una vez\r\n')
            sleep(0.3)
            @socket.puts use_shortcut('add 456 0 60 14 \r\nuna Iguana,\r\n')
            sleep(0.3)
            @socket.puts use_shortcut('add 789 0 60 22 \r\ncon una ruana de lana,\r\n')
            sleep(0.3)
            @socket.puts use_shortcut('add 101 0 60 20 \r\npeinandose la melena\r\n')
            sleep(0.3)
            @socket.puts use_shortcut('add 112 0 60 23 \r\njunto al rio magdalena\r\n')
            sleep(0.3)
            @socket.puts use_shortcut('gets 123 456 789 101 112 100 200 300')
            sleep(0.3)
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

  def use_shortcut (line)
    puts "shortcut ussed... sending: #{line} "
    return line
  end

  # ------------ RECEIVE MESSAGES FROM SERVER ------------

  def listen_server
    begin
      Thread.new do
        loop do
          get_message
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  def get_message
    server_response = @socket.gets
    if server_response != nil
      handle_message(server_response.chomp)
    end
  end

  def handle_message(message)
    if message.include? 'SEND DATA'
      puts "Storage command accpeted. To continue #{message}"
    elsif message.include? 'MULTI_LINE'
      get_multi_line(message)
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

  def get_multi_line(message)
    parts = message.chomp.split('\r\n')
    parts.delete_at(0)
    if parts.length > 0
      parts.each do |line|
        puts line
        puts 'Write your command' if line == 'END'
      end
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
