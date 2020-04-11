# frozen_string_literal: true
# We'll use Hash so we avoid existing keys entries

require 'concurrent-ruby'

require_relative './models/cache_data.rb'
require_relative './models/cache_result.rb'

# Class Memcached
class Memcached

  MESSAGES = { stored: 'STORED', not_stored: 'NOT_STORED', exists: 'EXISTS', not_found: 'NOT_FOUND', found: 'FOUND' }.freeze
  MY_MESSAGES = { all_found: 'ALL_FOUND', only_found: 'ONLY_FOUND', none_found: 'NONE_FOUND'}

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
    if valid_for_retrieval?(key)
      entry = @hash_storage[key]
      CacheResult.new(true, "#{MESSAGES[:found]} [key: #{key}, data: #{entry.data}]" , entry)
    else
      CacheResult.new(false, "#{MESSAGES[:not_found]} [key: #{key}]", nil)
    end
  end

  def gets(keys)
    entries = Array.new(keys.length)
    found_keys = 0

    results = "MULTI_LINE\n"
    keys.each do |key|
      get_result = get(key)
      entries << get_result.args if get_result.args != nil  # the found cache entry
      results += "#{get_result.message}\n"
      found_keys += 1 unless get_result.message.include?MESSAGES[:not_found]
    end
    results += 'END'

    if found_keys == keys.length
      header = "#{MY_MESSAGES[:all_found]}\n"
    elsif found_keys == 0
      header = "#{MY_MESSAGES[:none_found]}\n"
    else
      header = "#{MY_MESSAGES[:only_found]}\n"
    end

    final_message = header + results
    CacheResult.new(found_keys>0, final_message, entries)
  end

  # ---         MEMCACHED STORAGE METHODS          ---

  def cas
    # TODO
  end

  def set(key, data, flags, exp_time)
    cas_unique = next_cas_val # get cas value and increment by 1
    entry = CacheData.new(key: key, data: data, flags: flags, exp_time: exp_time, cas_unique: cas_unique)
    @hash_storage[key] = entry # add cache data to the storage
    CacheResult.new(true, "#{MESSAGES[:stored]} [key: #{key}, data: #{data}]", entry)
  end

  def add(key, data, flags, exp_time)
    if !exists?(key)
      set(key, data, flags, exp_time)
    else
     # Couldn't add, key already exists
     CacheResult.new(false,"#{MESSAGES[:exists]} Key #{key} is already registered", nil)
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

  # true if hash storage has the specified key stored
  def stored?(key)
    @hash_storage.key?(key)
  end

  # true if the key is stored and has not expired
  def exists?(key)
    @hash_storage.key?(key) && (@hash_storage[key].exp_time.nil? || @hash_storage[key].exp_time > Time.now)
  end

  # Use this method when is certain that the cache exists
  # true if isn't null and time elapsed is bigger than expiration time
  def expired?(key)
    expired = !@hash_storage[key].exp_time.nil? && @hash_storage[key].exp_time <= Time.now
  end

  # Use this method to find if it's a valid key for retrieval
  def valid_for_retrieval?(key)
    cache = @hash_storage[key]
    if exists?(key) && !cache.nil?
      return true
    elsif !cache.nil? && expired?(key)
      remove_entry(key)
      return false
    end
  end

  # ===================================================
  # ===            REMOVE CACHE METHODS             ===
  # ===================================================

 # Removes specific cache entry by key
  def remove_entry(key)
    @hash_storage.delete(key)
  end

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
