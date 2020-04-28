# frozen_string_literal: true

require 'socket'
require 'objspace'

class Client

  def initialize(socket)
    @socket = socket
    @enable_easy_input = true
    @send_requests = send_requests
    @listen_server = listen_server
    @send_requests.join
    @listen_server.join
  end

  trap 'SIGINT' do
    print "Something went wong... Connection Closed! :'C"
    exit 100 # Bad Way
  end

  # -------------- SEND MESSAGES TO SERVER--------------

  def send_requests
    begin
      Thread.new do
        loop do
          message = $stdin.gets.chomp
          puts 'Write your command' if message.split("\s").include? 'noreply'
          if @enable_easy_input
            easy_inpu(message) # the following code is just to make easier doing some simple testing
          else
            puts message
            @socket.puts message # this should be enoguh to send requests to the server
          end
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  def easy_inpu(message)
    # the following code is just to make easier doing some simple testing
    if message == 'add'
      puts 'Write the data you want to send....'
      data = gets.chomp
      @socket.puts add_line_generator(ttl: 300, data: data) # ttl 300 = 5 minutes
    elsif message == 'cas'
      @socket.puts use_shortcut('cas 12345 0 180 15 321 noreply')
    elsif message == 'tigres'
        @socket.puts use_shortcut('Tres tristes tigres')
    elsif message == 'multi'
      @socket.puts add_line_generator(key: 123, ttl: 300, data: "Habia una vez")
      sleep(0.5) # gives time to server to anwer the each request
      @socket.puts add_line_generator(key: 456, ttl: 300, data: "una Iguana,")
      sleep(0.5) # gives time to server to anwer the each request
      @socket.puts add_line_generator(key: 789, ttl: 300, data: "con una ruana de lana,")
      sleep(0.5) # gives time to server to anwer the each request
      @socket.puts add_line_generator(key: 101, ttl: 300, data: "peinandose la melena")
      sleep(0.5) # gives time to server to anwer the each request
      @socket.puts add_line_generator(key: 112, ttl: 300, data: "junto al rio magdalena")
      sleep(0.5) # gives time to server to anwer the each request
      @socket.puts use_shortcut('gets 123 456 789 101 112 100 200 300')
      sleep(0.5) # gives time to server to anwer the each request
    else
      @socket.puts message # this should be enoguh to send requests to the server
    end
  end

  def use_shortcut (line)
    puts "shortcut used... sending: #{line} "
    return line
  end

  def add_line_generator (args)
    key   = args[:key] != nil ? args[:key] : rand(999)
    ttl   = args[:ttl]
    data  = args[:data]
    bytes = data.bytesize
    line  = 'add ' + key.to_s + ' 0 ' + ttl.to_s + ' ' + bytes.to_s + ' \r\n' + data + '\r\n'
    use_shortcut(line)
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
      puts "Write your command\n"
    end
  end

  def get_multi_line(message)
    parts = message.chomp.split('\r\n')
    parts.delete_at(0)
    if parts.length > 0
      parts.each do |line|
        sub_lines = line.chomp.split('\n')
        sub_lines.each do |sub|
          puts sub
        end
        puts 'Write your command' if line.include? ('END')
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

socket = TCPSocket.open('localhost', 8080)
Client.new(socket)
