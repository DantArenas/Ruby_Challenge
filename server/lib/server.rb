# frozen_string_literal: true

require 'socket'            # Ruby Class to Handle TCPServer
require 'concurrent-ruby'   # Ruby Gem to handle Concurrency

require_relative 'memcached.rb'
require_relative 'client_handler.rb'

# ===================================================
# ===                SERVER CLASS                 ===
# ===================================================

# Class Server
class Server
  MAX_THREADS = 20 # default 20
  SERVER_VERSION = '0.0.3'.freeze

  def initialize(args)
    @port = args[:port]
    @tcp_Server = TCPServer.open("localhost", @port)
    @memcached = Memcached.new

    @clients = []
    puts "Server Up and Running [PORT: #{@port}]"
          puts "WAITING FOR REQUESTS"
    run
  end

  trap 'SIGINT' do
    close_server
  end

  # ---------- Server main cicle (Adding Clients) ----------

  def run
    loop do
      new_client = @tcp_Server.accept
      client_handler = ClientHandler.new(id: @clients.length()+1, clientSocket: new_client, memcached: @memcached)
      @clients << client_handler

      Thread.start(client_handler) do |handler| # open thread for each accepted connection
        puts "New connection established! Now #{@clients.length()} clients :>"
        puts "WAITING FOR REQUESTS"
        handler.send("Server: Connection established with #{handler}")
        handler.send("Server: You may introduce commands now")
        listen_requests(handler) # allow communication
      end
    end.join
  end

  # This method only handles request to the server
  def listen_requests(handler)
    loop do
      message = handler.listen
      if message != nil && message != ""
        command = message.split("\s")[0]
        if command.include? "close"
          remove_client(handler)
        elsif command.include? "clients"
          handler.send("Server has #{@clients.length()} clients connected :D")
        elsif message.include? "server -v"
          handler.send("Your SERVER VERSION is #{SERVER_VERSION} ;)")
        else # isn't a server request, let the client handler manage it
          handler.manage_requests(message)
        end
      end
    end
  end

# ---------- Removigin Client Connections ----------

def remove_client(handler)
  handler.close_connection
  # TODO check that only deletes the specific socket.
  @clients.delete(handler)
  puts "Removed Client. #{@clients.length()} connections remaining"
end

def self.close_all_clients_connections
  if @clients != nil #TODO, clients is reading as null
    @clients.each {|c| c.close_connection}
  end
end

def self.close_server
  puts 'Closing all Connections'
  close_all_clients_connections
  puts 'Closing Server'
  exit 0
end

  # ---------- MEMCACHED RELATED METHODS ----------

  def stats
    #TODO
  end

  def version
    puts "Server Version: #{SERVER_VERSION}"
  end

  def verbosity
    #TODO
  end

#  def quit(socket)
#    remove_client(socket)
#  end

end # Class Server

# ===================================================
# ===           HERE WE LAUNCH THE SERVER         ===
# ===================================================

port = 8080 # default 3000
my_memcached_server = Server.new(port: port)
