# frozen_string_literal: true

class CommandResponse
  attr_reader :success, :message, :args

  def initialize(success, message, args)
    @success = success
    @message = message
    @args = args
  end
end
