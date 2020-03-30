# frozen_string_literal: true

require_relative 'command_handler.rb'

class ClientHandler

  def initialize(memcache)
    puts 'Client Handler Initialize'
    @executor = CommandHandler.new(memcache)
  end

  def handle_client(socket, closing_callback)
    # TODO get socket data (line)
    if (false)
    closing_callback.call(socket)
    end
  end

end
