# frozen_string_literal: true

class CommandResponse
  attr_reader :success, :message, :args

  def initialize(success, message, args)
    @success = success
    @message = message
    @args = args
  end

  def add_data(data)
    @args[:data] = data if data != nil
  end
end
