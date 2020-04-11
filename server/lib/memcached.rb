# frozen_string_literal: true
# We'll use Hash so we avoid existing keys entries

require 'concurrent-ruby'

require_relative './models/cache_data.rb'
require_relative './models/cache_result.rb'

# Class Memcached
class Memcached

  MESSAGES = { stored: 'STORED', not_stored: 'NOT_STORED', exists: 'EXISTS', not_found: 'NOT_FOUND', found: 'FOUND' }.freeze
  MY_MESSAGES = { all_found: 'ALL_FOUND', only_found: 'ONLY_FOUND', none_found: 'NONE_FOUND', error: 'ERROR', success: 'SUCCESS'}

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
    results = ''
    keys.each do |key|
      get_result = get(key)
      entries << get_result.args if get_result.args != nil  # the found cache entry
      results += get_result.message + '\r\n'
      found_keys += 1 unless get_result.message.include?MESSAGES[:not_found]
    end
    results += 'END'

    if found_keys == keys.length
      header = MY_MESSAGES[:all_found]
    elsif found_keys == 0
      header = MY_MESSAGES[:none_found]
    else
      header = MY_MESSAGES[:only_found]
    end
    header += ' ----------------- '

    final_message = 'MULTI_LINE\r\n' + header + '\r\n' + results
    CacheResult.new(found_keys>0, final_message, entries)
  end

  def get_all
    entries = Array.new()
    found_keys = 0
    results = 'ALL CACHE\r\n'
    @hash_storage.each do |key, value|
      get_result = get(key)
      entries << get_result.args if get_result.args != nil  # the found cache entry
      results += get_result.message + '\r\n'
      found_keys += 1 unless get_result.message.include?MESSAGES[:not_found]
    end
    results += 'END'

    final_message = 'MULTI_LINE\r\n' + results
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

  def replace(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(success: false, message: MESSAGES[:not_stored])
    else
      set(key, data, flags, exp_time)
    end
  end

  def append(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(success: false, message: MESSAGES[:not_stored])
    else
      current_entry = @hash_storage[key]
      set(key, current_entry.data + data, flags, exp_time)
    end
  end

  def prepend(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(success: false, message: MESSAGES[:not_stored])
    else
      current_entry = @hash_storage[key]
      set(key, data + current_entry.data, flags, exp_time)
    end
  end

  def increment
    # TODO
  end

  def delete(key)
    if exists? (key)
      remove_entry(key)
      CacheResult.new(true,"#{MY_MESSAGES[:success]} Key #{key} deleted", nil)
    else
      CacheResult.new(false,"#{MESSAGES[:not_found]} Key #{key} not found", nil)
    end
  end

  def clear_cache
    @hash_storage.clear
    if @hash_storage.length == 0
      CacheResult.new(true,"#{MY_MESSAGES[:success]} All cache deleted", nil)
    else
      CacheResult.new(false,"#{MY_MESSAGES[:error]} could not flush all", nil)
    end
  end

  def flush_all(seconds)
      seconds == nil ? sleep(5) : sleep(seconds) # default 5 seconds
      handle_thr = Thread.new {sleep(seconds)}
      Thread.kill(handle_thr) # sends exit() to thr
      clear_cache # flush all cache
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
      sleep(1) # default 5 seconds
      # --- Searching Expired Cache ---
      @hash_storage.each do |key, cache|
        if expired?(key)
          remove_entry(key)
          puts "Removing #{cache} with key: #{key}"
        end
      end
      @cleaning_cache = false
      # puts 'Cache Cleaned'
    end
  end

end
