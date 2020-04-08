# frozen_string_literal: true

class CacheData
  # Kind of vars "getters"
  attr_reader :key, :data, :exp_time, :flags, :cas_unique

  def initialize(args)
    @key = args[:key]
    @data = args[:data]
    @exp_time = args[:exp_time].zero? ? nil : Time.now + args[:exp_time]
    @flags = args[:flags]
    @cas_unique = args[:cas_unique] # Check And Set
  end
end
