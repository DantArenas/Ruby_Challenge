# frozen_string_literal: true

class CacheStorageResult
  attr_reader :success, :message, :cache_entry

  def initialize(args)
    @success = args[:success]
    @message = args[:message]
    @cache_entry = args[:cache_entry]
  end
end
