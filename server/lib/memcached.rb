# frozen_string_literal: true

require_relative './models/cache_data.rb'   # stores cache information
require_relative './models/cache_result.rb' # stores command response information

# Class Memcached
class Memcached

  MESSAGES = { stored: 'STORED', not_stored: 'NOT_STORED', exists: 'EXISTS', not_found: 'NOT_FOUND', found: 'FOUND' }.freeze
  # This messages are not specified by the protocol, but I find them useful
  MY_MESSAGES = { all_found: 'ALL_FOUND',
                  only_found: 'ONLY_FOUND',
                  none_found: 'NONE_FOUND',
                  error: 'ERROR',
                  success: 'SUCCESS',
                  expired: 'EXPIRED',
                  no_numeric_type: 'NO_NUMBER'
                }

  def initialize
    # We'll use Hash so we avoid existing keys entries
    @hash_storage = Hash.new
    @cas_value = 2**32 # CAS = Check And Set
    @cleaning_cache = false
  end

  # ===================================================
  # ===    MEMCACHED RETRIEVAL PROTOCOL METHODS     ===
  # ===================================================

  # All this methods return a CacheResult Object, wich contains 3 variables
  # 1. Success, if the operation was successful
  # 2. Message, wich contains information about the operation
  # 3. Args, to storage the found items, such as cache entries. Nil if none found

  # return the found cache entry as args
  def get(key)
    cache = @hash_storage[key]
    if exists?(key) && !cache.nil?
      CacheResult.new(true, "#{MESSAGES[:found]} [key: #{key}, data: #{cache.data}]" , cache)
    elsif !exists?(key) && cache.nil?
      CacheResult.new(false, "#{MESSAGES[:not_found]} [key: #{key}]", nil)
    elsif expired?(key)
      remove_entry(key)
      CacheResult.new(false, "#{MY_MESSAGES[:expired]} [key: #{key}]", nil)
    end
  end

  # receives multiple keys and return the cache entry related to each one when found
  def gets(keys)
    entries = Array.new
    found_keys = 0
    results = ''
    keys.each do |key|
      get_result = get(key)
      entries << get_result.args if get_result.args != nil  # the found cache entry
      results += get_result.message + '\r\n'
      found_keys += 1 unless get_result.message.include?MESSAGES[:not_found]
    end
    results += 'END\n\n'

    header = '\n\n'
    if found_keys == keys.length
      header += MY_MESSAGES[:all_found]
    elsif found_keys == 0
      header += MY_MESSAGES[:none_found]
    else
      header += MY_MESSAGES[:only_found]
    end
    header += ' ----------------- \n'

    final_message = 'MULTI_LINE\r\n' + header + '\r\n' + results
    CacheResult.new(found_keys>0, final_message, entries)
  end

  # returns all cache stored, wasn't specified in the protocol
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

  def gat
    ## TODO:
  end

  def gats
    ## TODO:
  end

  # ===================================================
  # ===     MEMCACHED STORAGE PROTOCOL METHODS      ===
  # ===================================================

  def cas(key, data, flags, exp_time, cas_unique)
    if !exists?(key)
      CacheResult.new(false,  "#{MESSAGES[:not_found]}", nil)
    elsif @hash_storage[key].cas_unique != cas_unique
      CacheResult.new(false, "#{MESSAGES[:exists]}", nil)
    else
      set(key, data, flags, exp_time)
    end
  end

  # set cache entry with the specified key.
  # Any cache entry already associated to the key is overwritten
  # If there's not any cache entry associated, it stores a new one
  def set(key, data, flags, exp_time)
    cas_unique = next_cas_val # get cas value and increment by 1
    entry = CacheData.new(key: key, data: data, flags: flags, exp_time: exp_time, cas_unique: cas_unique)
    @hash_storage[key] = entry # add cache data to the storage
    CacheResult.new(true, "#{MESSAGES[:stored]} [key: #{key}, data: #{data}]", entry)
  end

  # if there's no other entry associated to the key, adds it to the storage
  def add(key, data, flags, exp_time)
    if !exists?(key)
      set(key, data, flags, exp_time)
    else
     # Couldn't add, key already exists
     CacheResult.new(false,"#{MESSAGES[:exists]} Key #{key} is already registered", nil)
    end
  end

  # replaces the data stored in a specific key if exists
  def replace(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(false, MESSAGES[:not_stored], nil)
    else
      set(key, data, flags, exp_time)
    end
  end

  # Adds data to a specific key, after the contained data
  def append(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(false, MESSAGES[:not_stored], nil)
    else
      current_entry = @hash_storage[key]
      set(key, current_entry.data + data, current_entry.flags, current_entry.exp_time)
    end
  end

  # Adds data to a specific key, before the contained data
  def prepend(key, data, flags, exp_time)
    if !exists?(key)
      CacheResult.new(false, MESSAGES[:not_stored], nil)
    else
      current_entry = @hash_storage[key]
      set(key, data + current_entry.data, current_entry.flags, current_entry.exp_time)
    end
  end

  def increment(key, value)
    if !exists?(key)
       CacheResult.new(false, MESSAGES[:not_stored], nil)
    else
      current_entry = @hash_storage[key]
      num_data = current_entry.data
      if !is_unsigned_int?(num_data)
         return CacheResult.new(false,  MY_MESSAGES[:no_numeric_type], nil)
      end
      data = Integer(num_data) + value.to_i
      set(key, data, current_entry.flags, current_entry.exp_time)
    end
  end

  def decrement(key, value)
    if !exists?(key)
       CacheResult.new(false, MESSAGES[:not_stored], nil)
    else
      current_entry = @hash_storage[key]
      num_data = current_entry.data
      if !is_unsigned_int?(num_data)
         return CacheResult.new(false, MY_MESSAGES[:no_numeric_type], nil)
      end
      data = Integer(num_data) - value.to_i
      set(key, data, current_entry.flags, current_entry.exp_time)
    end
  end

  # Deletes cache entry associated to the specified key if found
  def delete(key)
    if exists? (key)
      remove_entry(key)
      CacheResult.new(true,"#{MY_MESSAGES[:success]} Key #{key} deleted", nil)
    else
      CacheResult.new(false,"#{MESSAGES[:not_found]} Key #{key} not found", nil)
    end
  end

  # deletes all stored cache entries
  def clear_cache
    @hash_storage.clear
    if @hash_storage.length == 0
      CacheResult.new(true,"#{MY_MESSAGES[:success]} All cache deleted", nil)
    else
      CacheResult.new(false,"#{MY_MESSAGES[:error]} could not flush all", nil)
    end
  end

  # after specified time, deletes all stored cache entries
  def flush_all(seconds)
      seconds == nil ? sleep(5) : sleep(seconds) # default 5 seconds
      handle_thr = Thread.new {sleep(seconds)}
      Thread.kill(handle_thr) # sends exit() to thr
      clear_cache # flush all cache
  end

  # ===================================================
  # ===            CACHE STATUS METHODS             ===
  # ===================================================

  # returns cas value and increment it by 1
  def next_cas_val
    val = @cas_value
    @cas_value += 1
    val
  end

  # true if hash storage has the specified key stored
  def stored?(key)
    @hash_storage.key?(key)
  end

  # true if the key is stored and has not expired
  def exists?(key)
    @hash_storage.key?(key) && !expired?(key)
  end

  # Use this method when is certain that the cache exists
  # true if isn't null and time elapsed is bigger than expiration time
  def expired?(key)
    return true unless @hash_storage[key] != nil
    exp_time = @hash_storage[key].exp_time
    return false if exp_time == 0 # when zero, cache never expires
    expired = !exp_time.nil? && @hash_storage[key].exp_time <= Time.now.to_i
  end

  def is_unsigned_int?(string)
    is_integer?(string) && Integer(string) >= 0
  end

  def is_integer?(string)
    int_regex = /\A[-+]?\d+\z/
    int_regex === string
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

 # Finds & Removes expired cache entries
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

end # memcaches class
