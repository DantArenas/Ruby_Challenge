# frozen_string_literal: true
# We'll use Hash so we avoid existing keys entries

require 'concurrent-ruby'

require_relative './models/cache_storage_result.rb'

# Class Memcached
class Memcached

  MESSAGES = { stored: 'STORED', not_stored: 'NOT_STORED', exists: 'EXISTS', not_found: 'NOT_FOUND' }.freeze

  def initialize
    @hash_storage = Concurrent::Hash.new
    @cas_value = 2**32 # CAS = Check And Set
    @cleaning_cache = false
  end

  # ===================================================
  # ===         MEMCACHED PROTOCOL METHODS          ===
  # ===================================================

  # ---         MEMCACHED RETRIEVAL METHODS          ---

  def get(key)
    cache
  end

  def gets(key)
    cache
  end

  # ---         MEMCACHED STORAGE METHODS          ---

  def cas
    # TODO
  end

  def set(key, data, flags, exp_time)
    cas_unique = next_cas_val # get cas value and increment by 1
    entry = CacheData.new(key: key, data: data, flags: flags, exp_time: exp_time, cas_unique: cas_unique)
    @hash_storage[key] = entry
    CacheStorageResult.new(success: true, message: MESSAGES[:stored], entry: entry)
  end

  def add(key, data, flags, exp_time)
    if !exists?(key)
      set(key, data, flags, exp_time)
    else
     # Couldn't add, key already exists
     puts "Key #{key} is already stored"
    end
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
  # ===            USEFUL METHODS             ===
  # ===================================================

  # returns cas value and increment it by 1
  def next_cas_val
    val = @cas_value
    @cas_value += 1
    val
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
