# frozen_string_literal: true

# Meta Commands are to include yet

class CommandHandler

  STORAGE_COMMANDS = %w[set add replace append prepend cas].freeze
  RETRIEVAL_COMMANDS = %w[get gets hello].freeze
  MESSAGE = {error: 'ERROR'} # syntax error

  def initialize(memcached, client_socket)
    @cache = memcached
    @client_socket = client_socket
  end

 # Here we verify the command structure
  def split_command(command_line)
    parts = command_line.split("\s")
    command = parts[0] # first part must be the command
    parts.delete_at(0) # removes the command from the line

    if is_retrieval?(command)  # Is Retrieval Request?
      manage_retrieval(command, parts)
    elsif is_storage?(command) # Is Storage Request?
      manage_storage(command, parts)
    else                       # Is not a command
      manage_no_command(command_line)
    end
  end

  # ----------------------------------------------------------------
  # ---                     MANAGE REQUESTS                      ---
  # ----------------------------------------------------------------
  # Here we'll manage the incomming commands

  def manage_storage(command, args)
    ## TODO: Verify  the command is complete and includes necessary data
    @client_socket.puts "Soon we'll manage your storage request"
  end

  def manage_retrieval(command, args)
    ## TODO: Answer the Request
    if command.eql? 'hello'
      salute
    else
      @client_socket.puts "Soon we'll manage your retieval request"
    end
  end

  # ----------------------------------------------------------------
  # ---                     OTHER RESPONSES                      ---
  # ----------------------------------------------------------------

  def manage_no_command(line)
    # TODO list the expected commands and their function
    if line.include? "fine"
      @client_socket.puts "Server Responded: Great! Then, how can I help you?"
    else
      @client_socket.puts "-'#{line}'- isn't a command"
    end
  end

  def salute
    @client_socket.puts "Server Says: Hey There! How are you?"
  end

  # ----------------------------------------------------------------
  # ---                   VERIFICATION METHODS                   ---
  # ----------------------------------------------------------------

  def is_storage?(command)
    STORAGE_COMMANDS.include?(command)
  end

  def is_retrieval?(command)
    RETRIEVAL_COMMANDS.include?(command)
  end

end# Command Handler Class
