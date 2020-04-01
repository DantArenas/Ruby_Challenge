# frozen_string_literal: true
# We'll use Hash so we avoid existing keys entries

require 'concurrent-ruby'

# Class Memcached
class Memcached

  def initialize
    @hash_storage = Concurrent::Hash.new
    @unique_value = 1 # TODO
    @cleaning_cache = false
  end

  # ===================================================
  # ===         MEMCACHED PROTOCOL METHODS          ===
  # ===================================================

  def get(key)
    cache
  end

  def set
    # TODO
  end

  def add
    # TODO
  end

  def replace
    # TODO
  end

  def append
    # TODO
  end

  def prepend
    # TODO
  end

  def increment
    # TODO
  end

  def delete
    # TODO
  end

  def flush_all
    # TODO
  end

  def flush_all(args)
      seconds = args[:seconds]
  end

  # ===================================================
  # ===            CACHE STATUS METHODS             ===
  # ===================================================

  # true if the key is stored and has not expired
  def exists?(key)
    @hash_storage.key?(key) && (@hash_storage[key].exp_time.nil? || @hash_storage[key].exp_time > Time.now)
  end

  # Use this method when is certain that the cache exists
  # true if isn't null and time elapsed is bigger than expiration time
  def expired?(key)
    expired = !@hash_storage[key].exp_time.nil? && @hash_storage[key].exp_time <= Time.now
  end


  # ===================================================
  # ===            REMOVE CACHE METHODS             ===
  # ===================================================

  def clean_cache
    unless @hash_storage.empty? && @cleaning_cache
      @cleaning_cache = true
      Thread.new {remove_expired_cache} # Thread to Handle the process
    else
      # Already Clean
      # puts 'Cache Clean'
    end
  end

  def remove_expired_cache
    while @cleaning_cache
      sleep(5) # 5 seconds
      # --- Searching Expired Cache ---
      @hash_storage.each do |key, cache|
        if expired?(key)
          @hash_storage.delete(key)
          puts "Removing #{cache} with key: #{key}"
        end
      end
      @cleaning_cache = false
      # puts 'Cache Cleaned'
    end
  end

end
