# frozen_string_literal: true

# Meta Commands are to include yet

class CommandHandler

  def initialize(memcached)
    @cache = memcached
  end

  def split_line(command_line)
    parts = command_line.split("\s")
  end

  def valid_command? (command)
  end
end
