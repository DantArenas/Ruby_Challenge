# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/memcached.rb'

class CommandExecutorTest < Test::Unit::TestCase

  def setup
    @cache = Memcached.new
  end

  # ==================== SET & ADD ====================

  def test_set_key_value
    result = @cache.set('Key', 'Data', 0, Time.now.to_i + 60)
    cache = @cache.get('Key').args

    assert_true result.success
    assert_equal 'STORED', result.message.chomp.split("\s")[0]
    assert_equal 'Data', cache.data
  end

  def test_add_non_existing
    result = @cache.add('Key', 'Data', 0, Time.now.to_i + 60)
    cache = @cache.get('Key').args

    assert_true result.success
    assert_equal 'STORED', result.message.chomp.split("\s")[0]
    assert_equal 'Data', cache.data
  end

  def test_add_already_existing
    @cache.set('Key', 'Data', 0, Time.now.to_i + 60)
    result = @cache.add('Key', 'Data', 0, Time.now.to_i + 60)
    cache = @cache.get('Key').args

    assert_false result.success
    assert_equal 'EXISTS', result.message.chomp.split("\s")[0]
    assert_equal 'Data', cache.data
  end

  def test_add_already_existing_expired_key
    @cache.set('Key', 'Data', 0, Time.now.to_i - 1)
    result = @cache.add('Key', 'Data', 0, Time.now.to_i + 60)
    cache = @cache.get('Key').args

    assert_true result.success
    assert_equal 'STORED', result.message.chomp.split("\s")[0]
    assert_equal 'Data', cache.data
  end

  # ==================== REPLACE ====================

  def test_replace_existing
   @cache.add('Key', 'Data1', 0, Time.now.to_i + 60)
   result = @cache.replace('Key', 'Data2', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 'Data2', cache.data
  end

  def test_replace_non_existing
   result = @cache.replace('Key', 'Data2', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  def test_replace_existing_expired
   @cache.add('Key', 'Data1', 0, Time.now.to_i - 1)
   result = @cache.replace('Key', 'Data2', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  # ==================== CAS ====================

  def test_cas_successfully
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
   cache = @cache.get('Key1').args
   cas_unique = cache.cas_unique

   result = @cache.cas('Key1', 'Data2', 2, Time.now.to_i + 70, cas_unique)
   cache = @cache.get('Key1').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 'Data2', cache.data
  end

  def test_cas_already_updated
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
   cache = @cache.get('Key1').args
   cas_unique = cache.cas_unique
   cas_unique += 100 # provide a different cas_unique, so that is rejected

   result = @cache.cas('Key1', 'Data2', 2, Time.now.to_i + 70, cas_unique)
   cache = @cache.get('Key1').args

   assert_false result.success
   assert_equal 'EXISTS', result.message.chomp.split("\s")[0]
   assert_equal 'Data1', cache.data
  end

  def test_cas_non_existent
   result = @cache.cas('Key1', 'Data2', 0, Time.now.to_i + 70, 22)

   assert_false result.success
   assert_equal 'NOT_FOUND', result.message.chomp.split("\s")[0]
  end

  # ==================== APPEND & PREPEND ====================

  def test_append_existing
   @cache.add('Key', 'Data1', 0, Time.now.to_i + 60)
   result = @cache.append('Key', '&Data2', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 'Data1&Data2', cache.data
  end

  def test_append_non_existing
   result = @cache.append('Key', '&Data2', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  def test_prepend_existing
   @cache.add('Key', 'Data1', 0, Time.now.to_i + 60)
   result = @cache.prepend('Key', 'Data2&', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 'Data2&Data1', cache.data
  end

  def test_prepend_non_existing
   result = @cache.prepend('Key', 'Data2&', 0, Time.now.to_i + 60)
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  # ==================== INCREMENT & DECREMENT ====================

  def test_increment_existing_numeric
   @cache.add('Key', '100', 0, Time.now.to_i + 60)
   result = @cache.increment('Key', '1')
   cache = @cache.get('Key').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 101, cache.data
  end

  def test_increment_non_existing
   result = @cache.increment('Key', '1')
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  def test_increment_existing_no_numeric
    @cache.add('Key', 'Hello_', 0, Time.now.to_i + 60)
    result = @cache.increment('Key', '1')
    cache = @cache.get('Key').args

    assert_false result.success
    assert_equal 'NO_NUMBER', result.message.chomp.split("\s")[0]
  end

  def test_decrement_existing_numeric
   @cache.add('Key', '100', 0, Time.now.to_i + 60)
   result = @cache.decrement('Key', '1')
   cache = @cache.get('Key').args

   assert_true result.success
   assert_equal 'STORED', result.message.chomp.split("\s")[0]
   assert_equal 99, cache.data
  end

  def test_decrement_non_existing
   result = @cache.decrement('Key', '1')
   cache = @cache.get('Key').args

   assert_false result.success
   assert_equal 'NOT_STORED', result.message.chomp.split("\s")[0]
  end

  def test_decrement_existing_no_numeric
    @cache.add('Key', 'Hello_s', 0, Time.now.to_i + 60)
    result = @cache.decrement('Key', '1')
    cache = @cache.get('Key').args

    assert_false result.success
    assert_equal 'NO_NUMBER', result.message.chomp.split("\s")[0]
  end

  # ==================== GET, GETS & GET_ALL ====================

  def test_get_non_existing
   result = @cache.get('non_existing')

   assert_false result.success
   assert_nil result.args
  end

  def test_gets_multiple_keys
   @cache.clear_cache # ensures is empty
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
   @cache.add('Key2', 'Data2', 0, Time.now.to_i + 60)
   @cache.add('Key3', 'Data3', 0, Time.now.to_i + 60)

   result = @cache.gets(%w[Key1 Key3])

   assert_true result.success
   assert_equal 2, result.args.length
  end

  def test_gets_multiple_some_non_existing
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
   result = @cache.gets(%w[Key1 Key3])

   assert_true result.success
   assert_equal 1, result.args.length
  end

  def test_get_all
   @cache.clear_cache # ensures is empty
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
   @cache.add('Key2', 'Data2', 0, Time.now.to_i + 60)
   @cache.add('Key3', 'Data3', 0, Time.now.to_i + 60)
   result = @cache.get_all

   assert_true result.success
   assert_equal 3, result.args.length
  end

  def test_get_all_empty_cache
   @cache.clear_cache # ensures is empty
   result = @cache.get_all

   assert_false result.success
   assert_equal 0, result.args.length
  end

  def test_get_expired_key_negative
   @cache.add('Key1', 'Data1', 0, Time.now.to_i - 1)
   result = @cache.get('Key1')

   assert_false result.success
   assert_equal 'EXPIRED', result.message.chomp.split("\s")[0]
   assert_nil result.args
  end

  def test_get_expired_key
   @cache.add('Key1', 'Data1', 0, Time.now.to_i + 1)
   sleep(2)
   result = @cache.get('Key1')

   assert_false result.success
   assert_equal 'EXPIRED', result.message.chomp.split("\s")[0]
   assert_nil result.args
  end

  # ==================== DELETE, CLEAR_CACHE & FLUSH_ALL ====================

  def test_delete_existing
    @cache.add('Key', 'Data_to_delete', 0, Time.now.to_i + 60)
    result = @cache.delete('Key')
    retrieval = @cache.get('Key')

    assert_true result.success
    assert_equal 'SUCCESS', result.message.chomp.split("\s")[0]
    assert_false retrieval.success
    assert_equal 'NOT_FOUND', retrieval.message.chomp.split("\s")[0]
  end

  def test_delete_non_existing
    result = @cache.delete('key')

    assert_false result.success
    assert_equal 'NOT_FOUND', result.message.chomp.split("\s")[0]
  end

  def test_delete_security
    @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
    @cache.add('Key2', 'Data2', 0, Time.now.to_i + 60)
    result = @cache.delete('Key1')
    retrieval = @cache.get('Key2')

    assert_true result.success
    assert_equal 'SUCCESS', result.message.chomp.split("\s")[0]
    assert_true retrieval.success
    assert_equal 'FOUND', retrieval.message.chomp.split("\s")[0]
    assert_equal 'Data2', retrieval.args.data
  end

  def test_clear_cache_existing
    @cache.clear_cache # to ensure cache memory is empty
    @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
    @cache.add('Key2', 'Data2', 0, Time.now.to_i + 60)
    @cache.add('Key3', 'Data3', 0, Time.now.to_i + 60)
    result = @cache.clear_cache
    retrieval = @cache.get_all.args

    assert_true result.success
    assert_equal 'SUCCESS', result.message.chomp.split("\s")[0]
    assert_equal 0, retrieval.length
  end

  def test_flush_all_existing
    @cache.clear_cache # to ensure cache memory is empty
    @cache.add('Key1', 'Data1', 0, Time.now.to_i + 60)
    @cache.add('Key2', 'Data2', 0, Time.now.to_i + 60)
    @cache.add('Key3', 'Data3', 0, Time.now.to_i + 60)
    result = @cache.flush_all(5) # waits 5 seconds before clearing cache
    retrieval = @cache.get_all.args

    assert_true result.success
    assert_equal 'SUCCESS', result.message.chomp.split("\s")[0]
    assert_equal 0, retrieval.length
  end
end # test class
