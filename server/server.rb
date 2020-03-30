# frozen_string_literal: true

require 'socket'            # Ruby Class to Handle TCPServer
require 'concurrent-ruby'   # Ruby Gem to handle Concurrency

require_relative 'memcached.rb'
require_relative 'client_handler.rb'

# Class Server
class Server
  MAX_THREADS = 20 # default 20

  def initialize(args)
    @port = args[:port]
    @memcached = Memcached.new
    @server_running = true
    @clients = []
    puts "Server Up and Running [PORT: #{port}]"
  end

  trap 'SIGINT' do
    puts 'Closing all Connections'
    close_all_clients_connections
    puts 'Closing Server'
    exit 130
  end

  def wait_for_connections
    tcp_Server = TCPServer.new('localhost', @port)
    @memcached.clean_cache
    client_handler = ClientHandler.new(@memcached)
    work_pool = Concurrent::FixedThreadPool.new(MAX_THREADS)

    puts 'WAITING FOR REQUESTS...'

    while @server_running
      begin
        new_client_connection(tcp_Server, work_pool, client_handler)
      rescue Errno => e
        # Could not connect with the client. Wait again.
        next
      end
    end
  end

  def new_client_connection(tcp_Server, work_pool, client_handler)
    new_client = tcp_Server.accept

    work_pool.post do
      client_handler.handle_client(new_client, method(:remove_client))
    end
    @clients << new_client
  end

  def remove_client(client_socket_to_remove)
    client_socket_to_remove.close
    @clients.delete(client_socket_to_remove)
  end

  def close_all_clients_connections
    @clients.each(&:close)
    @clients.clear
    puts 'CLOSED ALL CLIENTS\' CONNECTIONS'
  end
end

# ===================================================
# ===           HERE WE LAUNCH THE SERVER         ===
# ===================================================

port = 3000 # default 3000

my_memcached_server = Server.new(port: port)
my_memcached_server.wait_for_connections
