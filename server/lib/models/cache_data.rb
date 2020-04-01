# frozen_string_literal: true

class CacheData
  # Kind of vars "getters"
  attr_reader :key, :data, :exp_time, :flags, :unique_value

  def initialize(args)
    @key = args[:key]
    @data = args[:data]
    @exp_time = args[:exp_time].zero? ? nil : Time.now + args[:exp_time]
    @flags = args[:flags]
    @unique_value = args[:unique_value] # also refered as CAS Value?
  end

end
