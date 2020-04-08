# frozen_string_literal: true

class CommandResponse
  attr_reader :message, :cache_result

  def initialize(args)
    @message = args[:message]
    @cache_result = args[:cache_result]
  end
end
