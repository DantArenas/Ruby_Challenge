# frozen_string_literal: true

class CacheRetrievalResult
  attr_reader :success, :message, :cache_entries

  def initialize(args)
    @success = args[:success]
    @message = args[:message]
    @cache_entries = args[:cache_entries] # could be > 1
  end
end
