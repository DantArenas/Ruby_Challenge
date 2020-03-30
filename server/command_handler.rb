# frozen_string_literal: true

class CommandHandler

  def initialize(memcache)
    @cache = memcache
    puts 'Command Handler Initialize'
  end

  def split_line(command_line)
    parts = command_line.split("\s")
  end

  def valid_command? (command)
  end
end
