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
  SERVER_VERSION = '0.0.2'.freeze

  def initialize(args)
    @port = args[:port]
    @memcached = Memcached.new
    @server_running = true
    @clients = []
    puts "Server Up and Running [PORT: #{@port}]"
  end

  trap 'SIGINT' do
    close_server
  end

  # ---------- Server main cicle (Adding Clients) ----------

  def wait_for_connections
    tcp_Server = TCPServer.new('localhost', @port)
    @memcached.clean_cache # to start with a clean storage
    client_handler = ClientHandler.new(@memcached)
    work_pool = Concurrent::FixedThreadPool.new(MAX_THREADS)

    puts 'WAITING FOR REQUESTS...'

    while @server_running
      begin
        new_client_connection(tcp_Server, work_pool, client_handler)
      rescue Errno => e
        # Could not connect with the client. Wait again.
        puts 'No client, continuing'
        next
      end
    end
  end

  def new_client_connection(tcp_Server, work_pool, client_handler)
    new_client = tcp_Server.accept
    puts 'New Client Connected'
    work_pool.post do
      client_handler.handle_client(new_client, method(:remove_client))
    end
    @clients << new_client
  end

  # ---------- Removigin Client Connections ----------

  def self.remove_client(client_socket_to_remove)
    client_socket_to_remove.close
    puts 'Removing Client'
    # TODO check that only delet the specific socket.
    @clients.delete(client_socket_to_remove)
  end

  def self.close_all_clients_connections
    num_connections = 0
    if @clients != nil && @clients.length() > 0
      @clients.each do |c|
        c.close
        n+=1
      end
    end
    puts "CLOSED #{num_connections} CLIENT CONNECTIONS"
  end

  def self.close_server
    puts 'Closing all Connections'
    close_all_clients_connections
    puts 'Closing Server'
    exit 130
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

  def quit(socket)
    remove_client(socket)
  end

end

# ===================================================
# ===           HERE WE LAUNCH THE SERVER         ===
# ===================================================

port = 9100 # default 3000

my_memcached_server = Server.new(port: port)
my_memcached_server.wait_for_connections
