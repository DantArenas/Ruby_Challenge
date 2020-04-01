# frozen_string_literal: true

require 'socket'

# Client Class
class Client

  def initialize(args)
    @ip = args[:ip]
    @port = args[:port]
    @socket = TCPSocket.new(@ip, @port)
  end

  def connect
    waiting_command_message = 'Write your command'
    puts waiting_command_message

    message = gets
    while message != 'close'
      @socket.write(message)

      ready = IO.select(@socket, nil, nil, 10)
      if ready
        # do something
        line = @socket.gets
        puts line
      else
        # raise timeout
        puts 'Not in time. TIMEOUT'
      end

      #while line = @socket.gets
      #    puts line
      #end
      puts '...'
      puts waiting_command_message
    end
  end

end # Client Class

my_demo_client = Client.new(ip: '127.0.0.1', port: 9100)
my_demo_client.connect
