# frozen_string_literal: true
# Meta Commands are to include yet

require_relative './models/command_response.rb'

class CommandHandler

  STORAGE_COMMANDS = %w[set add replace append prepend incr decr cas].freeze
  RETRIEVAL_COMMANDS = %w[get gets delete flush_all stats hello].freeze
  FLAGS = %w[].freeze ## TODO: implement protocl flags
  MESSAGE = {error: 'ERROR', client_error: 'CLIENT_ERROR', server_error: 'SERVER_ERROR'}.freeze
  MY_MESSAGE = {not_command: 'NOT_COMMAND', not_enough_args: 'NOT_ENOUGH_ARGS', invalid_key: 'INVALID_KEY'}.freeze

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
      parse_storage(command, parts)
    else                       # Is not a command
      args = {line: command_line}
      CommandResponse.new(true, "#{MY_MESSAGE[:not_command]}: Not Command", args)
      # It's success = true so can be managed later
    end
  end

  # ----------------------------------------------------------------
  # ---                     MANAGE REQUESTS                      ---
  # ----------------------------------------------------------------
  # Here we'll parse the command line so we can decide what to do with it

  def parse_storage(command, parts)
    unless parts.length > 0
      return CommandResponse.new(false, "#{MY_MESSAGE[:not_enough_args]}: Missing args", nil)
    end

    # Here is the command line structure
    # NOTE: 'noreplay' may be included, adding 1 more "argument"
    # <incr decr> key amaunt
    # <set add replace append prepend> key flags exp_time bytes(data length) + data
    # <cas> key flags exp_time bytes(data length) cas_unique  + data

     key = parts[0] # all storage methods have key as first arg ument
     if !valid_key?(key) # see valid_key? method for more info about key validation
       return CommandResponse.new(false, "#{MY_MESSAGE[:invalid_key]}: Key is not valid", nil)
     end

     noreplay = parts[2] == 'noreplay' || parts[4] == 'noreplay' || parts[5] == 'noreplay'
     # true or false. 'noreply' should be the last arg every time

     if valid_args_count?(parts, 4, 6) # key + 3 args more + cas + noreplay (optional)
       flags = parts[1]
       exp_time = parts[2]
       bytes = parts[3]

       # lets check if the command args were send properly. Checking as cascade
       if !valid_flags?(flags)
         return respond_invalid("#{MESSAGE[:client_error]} Flags are not valid")
       elsif !is_unsigned_int(exp_time)
         return respond_invalid("#{MESSAGE[:client_error]} Expiration time is not valid")
       elsif !is_unsigned_int(bytes)
         return respond_invalid("#{MESSAGE[:client_error]} Bytes are not valid")
       elsif command == 'cas' && is_unsigned_int(parts[4])
         return respond_invalid("#{MESSAGE[:client_error]} CAS unique value is not valid")
       end

       args = { command: command, key: key, flags: flags, exp_time: generate_TTL(exp_time), bytes: Integer(bytes), noreplay: noreplay }
       args[:cas_unique] = Integer(parts[4]) if command == 'cas'
       CommandResponse.new(true, "STORED_ARGS_OBTAINED", args)

     elsif valid_args_count?(parts, 2, 3) # incr and decr: key + amaunt + noreplay (optional)
       amaunt = parts[1]

       if !is_unsigned_int(amaunt)
         return respond_invalid("#{MESSAGE[:client_error]} Amaunt is not valid")
       end

       args = { command: command, key: key, amaunt: amaunt, noreplay: noreplay}
       CommandResponse.new(true, "STORED_ARGS_OBTAINED", args)

     else # not valid args. Don't continue
       return CommandResponse.new(false, "#{MESSAGE[:not_enough_args]}: Invalid args count", nil)
     end
      ## TODO: Verify  the command is complete and includes necessary data
  end

  # ----------------------------------------------------------------
  # ---                     MANAGE REQUESTS                      ---
  # ----------------------------------------------------------------
  # Here we'll manage the answer of the validated request

  # Here we verify the command structure
   def manage_request(args)
     command = args[:command] # first part must be the command

     if is_retrieval?(command)  # Is Retrieval Request?
       ## TODO:
       manage_retrieval(command, args)
     elsif is_storage?(command) # Is Storage Request?
       manage_storage(command, args)
     else                       # Is not a command
       ## TODO:
       manage_no_command(args[:line]) # the complete line
     end
   end

  def manage_storage(command, args)
    if command.eql? 'add'
      ## TODO: CONNECTING MEMCACHED METHODS
      message_part1 = "Line ==> command:#{command} "
      message_part2 =("key:#{args[:key]} flags:#{args[:flags]} exp_time:#{args[:exp_time]}")
      message_part3 =("bytes:#{args[:bytes]} noreplay:#{args[:noreplay]}")

      message = message_part1 + message_part2 + message_part3
      CommandResponse.new(false, message, nil)
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
      CommandResponse.new(false, 'Server Responded: Great! Then, how can I help you?', nil)
    else
      CommandResponse.new(false, "-'#{line}'- isn't a command", nil)
    end
  end

  def salute
    CommandResponse.new(false, 'Server Says: Hey There! How are you?', nil)
  end

  def respond_invalid (message)
    CommandResponse.new(false, "Invalid Arg. #{message}", nil)
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

  def valid_args_count?(args, min_count, max_count) #is min and max inclusive
    valid = args.length >= min_count && args.length <= max_count
  end

  def valid_flags?(flags)
    if is_unsigned_int(flags)
      valid = Integer(flags) == 0
    else
      chars = flags.scan /\w/
      chars.each do |c|
        # if one isn't valid, then flag isn't valid
        valid = FLAGS.include?(c)
        return false if !valid
      end
    end
    valid
  end

  def generate_TTL(time) # Time To Live
    seconds = Integer(time) # time is already validated as unsigned integer
    if seconds > 2592000
      ## TODO: Manage the interpretation as a unix timestamp
      return seconds = 0
    end
    seconds
  end

  # ---------- Specific Validations ----------

  def is_unsigned_int(string)
    is_integer?(string) && Integer(string) >= 0
  end

  def is_integer?(string)
    int_regex = /\A[-+]?\d+\z/
    int_regex === string
  end

end# Command Handler Class
