# frozen_string_literal: true
# Meta Commands are to include yet

require_relative './models/command_response.rb'

class CommandHandler

  STORAGE_COMMANDS = %w[set add replace append prepend incr decr cas].freeze
  RETRIEVAL_COMMANDS = %w[get gets delete flush_all stats hello].freeze
  MESSAGE = {error: 'ERROR', not_enough_args: 'NOT_ENOUGH_ARGS', invalid_key: 'INVALID_KEY'}.freeze

  def initialize(memcached)
    @cache = memcached
  end

 # Here we verify the command structure
  def split_command(command_line)
    parts = command_line.split("\s")
    command = parts[0] # first part must be the command
    parts.delete_at(0) # removes the command from the parts list

    # All 'manage' methods return a command_response object
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

    key = args[0] # all storage methods have key as first argument

    if valid_args_count?(args, 2) # incr and decr
      amaunt = agrs[1]
    elsif valid_args_count?(args, 4) # key + 3 args more
      flags = args[1]
      exp_time = args[2]
      bytes = args[3]
    else
      # not valid args. Don't continue
      return CommandResponse.new(false,  "#{MESSAGE[:not_enough_args]}: Invalid args count", nil)
    end

    if !valid_key?(key)
      return CommandResponse.new(false,  "#{MESSAGE[:invalid_key]}: Key is not valid", nil)
    end

    ## TODO: Verify  the command is complete and includes necessary data
    if command.eql? 'add'
     ## TODO: CONNECTING MEMCACHED METHODS
    else
      CommandResponse.new(false,  "Soon we'll manage your storage request", nil)
    end
  end

  def manage_retrieval(command, args)
    ## TODO: Answer the Request
    if command.eql? 'hello'
      salute
    elsif command.eql? 'get'
      #@cache.get(args) ## TODO: CONNECTING MEMCACHED METHODS
    else
      CommandResponse.new(false,  "Soon we'll manage your retieval request", nil)
    end
  end

  # ----------------------------------------------------------------
  # ---                     OTHER RESPONSES                      ---
  # ----------------------------------------------------------------

  def manage_no_command(line)
    # TODO list the expected commands and their function
    if line.include? "fine"
      CommandResponse.new(  true,  'Server Responded: Great! Then, how can I help you?',  nil)
    else
      CommandResponse.new(  true,  "-'#{line}'- isn't a command",  nil)
    end
  end

  def salute
    CommandResponse.new(  true,  'Server Says: Hey There! How are you?',  nil)
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

  def valid_key?(key)
    # protocol specifies keys no longer than 250 characters
    # and keys must not include control characters or whitespace
    special = "?<>',?[]}{=-)(*&^%$#`~{}"
    regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
    return key.length() <= 250 && (key =~ regex).nil?
  end

  def valid_args_count?(args, expected_count)
    args.length == expected_count
  end

  def is_short_storage(command)
  end
end# Command Handler Class
