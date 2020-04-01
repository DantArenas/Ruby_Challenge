# frozen_string_literal: true

require_relative 'command_handler.rb'

class ClientHandler

  def initialize(memcached)
    # Memcached only needed as argumt to initialize command handler
    @command_handler = CommandHandler.new(memcached)
  end

  def handle_client(socket, closing_callback)
    puts 'Handling new client'
    while line = socket.gets # While incoming data
      handle_line(socket, line)
    end
    closing_callback.call(socket)
  end

  def handle_line(socket, line)
    clean_line = line.chomp.split('\r\n')
    socket.puts("Recived: #{clean_line}")
  end

end # Client Handler
