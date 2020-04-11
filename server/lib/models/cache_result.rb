# frozen_string_literal: true

class CacheResult
  attr_reader :success, :message, :args

  def initialize(success, message, args)
    @success = success
    @message = message
    @args = args # can store many things
  end
end
