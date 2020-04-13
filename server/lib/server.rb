# frozen_string_literal: true

require 'socket' # Ruby Class to Handle TCPServer

require_relative 'memcached.rb'
require_relative 'client_handler.rb'

# ===================================================
# ===                SERVER CLASS                 ===
# ===================================================

# Class Server
class Server
  SERVER_VERSION = '0.3.0'.freeze

  def initialize(args)
    @@port = args[:port]
    @tcp_Server = TCPServer.open("localhost", @@port)

    @@clients = [] # Here we'll store all the client handlers
    puts "Server Up and Running [PORT: #{@@port}]"
    puts "WAITING FOR REQUESTS"
    run # triggers a loop method
  end

  trap 'SIGINT' do
    puts "Clossing service at #{@@port}"
    puts "My clients #{@@clients.length}"
    close_server(@@clients) # if the execution stops
  end

  # ---------- Server main cicle (Adding Clients) ----------

  def run
    loop do
      memcached = Memcached.new # each client has its oun cache storage
      new_client = @tcp_Server.accept # when a new client connects to the server
      client_handler_id = rand(999999).to_s
      client_handler = ClientHandler.new(id: client_handler_id, clientSocket: new_client, memcached: memcached)
      @@clients << client_handler

      Thread.start(client_handler) do |handler| # open a new thread for each accepted connection
        # Here we inform the client of the connections. It's human made, so can be removed if not needed
        puts "New connection established! Now #{@@clients.length()} clients :>"
        puts "WAITING FOR REQUESTS"
        handler.send("Server: Connection established with Client Handler ID: #{client_handler_id}")
        handler.send("Server: You are the client ##{@@clients.length()}")
        handler.send("Server: You may introduce commands now")
        listen_requests(handler) # allow communication
      end
    end.join
  end

  # This method only handles request to the server
  # if the request can't be managed here, goes to the client handler
  # wich uses a command handler to answer the request
  def listen_requests(handler)
    loop do
      message = handler.listen # expecting array
      command_data = message[0] if message != nil

      if command_data != nil && command_data != ""
        command = command_data.split("\s")[0]
        if command == "close" || command == "quit"
          remove_client(handler) # when client disconnects or closes communication
        elsif command == "clients"
          handler.send("Server has #{@@clients.length()} clients connected :D")
        elsif command == "server -v"
          handler.send("Your SERVER VERSION is #{SERVER_VERSION} ;)")
        else # if isn't a server request, let the client handler manage it
          handler.manage_requests(message)
        end
      end
    end
  end

# ---------- Removigin Client Connections ----------

def remove_client(handler)
  handler.close_connection # tell the client handler to stop working
  @@clients.delete(handler) # finishes and delets the socket connection
  puts "Removed Client. #{@@clients.length()} connections remaining"
end

def self.close_all_clients_connections(clients)
  if clients.length > 0
    clients.each {|c| c.close_connection}
  else
    puts "No conncections to close"
  end
end

# This method is call when a problem stops the execution of the server or when closed
def self.close_server(clients)
  puts 'Closing all Connections'
  close_all_clients_connections(clients)
  puts 'Closing Server'
  exit 0
end

  # ---------- MEMCACHED RELATED METHODS ----------

  # This methods handle request related to the server
  def stats
    ## TODO:
  end

  def version
    puts "Server Version: #{SERVER_VERSION}"
  end

  def verbosity
    ## TODO:
  end

end # Class Server

# ===================================================
# ===           HERE WE LAUNCH THE SERVER         ===
# ===================================================

# Here we can choose a specific port for the server communications
# The IP is by default the localhost
port = 8080 # default 8080
my_memcached_server = Server.new(port: port)
