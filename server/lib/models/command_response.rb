# frozen_string_literal: true

class CommandResponse
  attr_reader :success, :message, :cache_result

  def initialize(success, message, cache_result)
    @success = success
    @message = message
    @cache_result = cache_result
  end
end
