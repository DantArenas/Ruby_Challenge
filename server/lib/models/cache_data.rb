# frozen_string_literal: true

class CacheData
  # Kind of vars "getters"
  attr_reader :key, :data, :exp_time, :flags, :cas_unique

  def initialize(args)
    @key = args[:key]
    @data = args[:data]
    @exp_time = args[:exp_time]
    @flags = args[:flags]
    @cas_unique = args[:cas_unique] # Check And Set
    # puts "Cache Data created with key #{key}, data #{data}, exp_time #{exp_time} & cas #{cas_unique}"
  end
end
