# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007, 2008, 2009, 2010           |
# +----------------------------------------------------------------------+
require (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/ ) ? 'mswin32/ibm_db.so' : 'ibm_db.so'
require 'stringio'
require 'test/unit'
require 'fileutils'

unless ENV['DB2INSTANCE']
  puts 'Database environment is not set up'
  puts 'Source the DB2 profile (please refer to the "Setup to utilize ibm_db" in the README file) and retry'
  exit -1
end

if (ENV['SINGLE_RUBY_TEST'] != nil && !ENV['SINGLE_RUBY_TEST'].empty?)
  testfile = "tests/" + ENV['SINGLE_RUBY_TEST']
  if RUBY_VERSION =~ /1.9/
    Dir[testfile].each { |file| require file }
  else
    Dir[testfile].each { |file| require file unless file =~ /unicode/i}
  end
else
  if RUBY_VERSION =~ /1.9/
    Dir['tests/test_*.rb'].each { |file| require file }
  else
    Dir['tests/test_*.rb'].each { |file| require file unless file =~ /unicode/i }
  end
end

module Config
  require 'yaml'
  configdata = open('config.yml') {|f| YAML::load f}
  configdata['connection'].each {|name,value| define_method(name) {value}}
  configdata['trusted_connection'].each {|name,value| define_method(name) {value}}

  alias db database
  alias username user
end

class TestIbmDb < Test::Unit::TestCase
  include Config

  ####################################################################
  #                         test support                             #
  ####################################################################

  def setup
    prepconn = IBM_DB::connect database, user, password
    IBM_DB::close prepconn
  end

  def teardown
    GC::start
  end

  def capture 
    stdout = $stdout
    buffer = $stdout = StringIO.new
    yield
    $stdout = stdout
    buffer.rewind
    buffer.read.strip.gsub("\r",'')
  end

  def expected_luw
    if (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/) && (RUBY_VERSION =~ /1.9/)
      method_caller = caller[1].split(':')[0] + ":"+ caller[1].split(':')[1]
    else
      method_caller = caller[1].split(':')[0]
    end
    open(method_caller,'rb') {|f| f.read}.gsub("\r",'').
      split("__LUW_EXPECTED__\n",2)[-1].strip . gsub(/\n__ZOS_EXPECTED__\n[\s\S]*/,"")
  end

  def expected_zos
    if (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/) && (RUBY_VERSION =~ /1.9/)
      method_caller = caller[1].split(':')[0] + caller[1].split(':')[1]
    else
      method_caller = caller[1].split(':')[0]
    end
    open(method_caller,'rb') {|f| f.read}.gsub("\r",'').
      split("__ZOS_EXPECTED__\n",2)[-1].strip . gsub(/\n__SYSTEMI_EXPECTED__\n[\s\S]*/,"")
  end

  def expected_systemi
    if (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/) && (RUBY_VERSION =~ /1.9/)
      method_caller = caller[1].split(':')[0] + caller[1].split(':')[1]
    else
      method_caller = caller[1].split(':')[0]
    end
    open(method_caller,'rb') {|f| f.read}.gsub("\r",'').
      split("\n__SYSTEMI_EXPECTED__\n",2)[-1].strip . gsub(/\n__IDS_EXPECTED__\n[\s\S]*/,"")
  end

  def expected_ids
    if (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/) && (RUBY_VERSION =~ /1.9/)
      method_caller = caller[1].split(':')[0] + caller[1].split(':')[1]
    else
      method_caller = caller[1].split(':')[0]
    end
    open(method_caller,'rb') {|f| f.read}.gsub("\r",'').
      split("\n__IDS_EXPECTED__\n",2)[-1].strip
  end

  def assert_expect &block
    prepconn = IBM_DB::connect database, user, password
    server = IBM_DB::server_info( prepconn )
    IBM_DB::close prepconn
    if (server.DBMS_NAME == 'AS')
      begin
        assert_equal expected_systemi, capture(&block)
      rescue NameError => exception
        raise unless exception.name == :unsupported
      end
    elsif (server.DBMS_NAME == 'DB2')
      begin
        assert_equal expected_zos, capture(&block)
      rescue NameError => exception
        raise unless exception.name == :unsupported
      end
    elsif (server.DBMS_NAME[0,3] == 'IDS')
      begin
        assert_equal expected_ids, capture(&block)
      rescue NameError => exception
        raise unless exception.name == :unsupported
      end
    else
      begin
        assert_equal expected_luw, capture(&block)
      rescue NameError => exception
        raise unless exception.name == :unsupported
      end
    end
  end

  def assert_throw_block &block
    prepconn = IBM_DB::connect database, user, password
    server = IBM_DB::server_info( prepconn )
    IBM_DB::close prepconn
    if (server.DBMS_NAME == 'AS')
      begin
        assert_throws expected_systemi, capture(&block)
      rescue NameError, ThreadError => error
        if UncaughtThrow[error.class] !~ error.message
          raise error
        end
      end
    elsif (server.DBMS_NAME == 'DB2')
      begin
        assert_throws expected_zos, capture(&block)
      rescue NameError, ThreadError => error
        if UncaughtThrow[error.class] !~ error.message
          raise error
        end
      end
    elsif (server.DBMS_NAME[0,3] == 'IDS')
      begin
        assert_throws expected_ids, capture(&block)
      rescue NameError, ThreadError => error
        if UncaughtThrow[error.class] !~ error.message
          raise error
        end
      end
    else
      begin
        assert_throws expected_luw, capture(&block)
      rescue NameError,ArgumentError => error
        if UncaughtThrow[error.class] !~ error.message
          raise error
        end
      end
    end
  end

  def assert_expectf &block
    prepconn = IBM_DB::connect database, user, password
    server = IBM_DB::server_info( prepconn )
    IBM_DB::close prepconn
    if (server.DBMS_NAME == 'AS')
      pattern = expected_systemi
    elsif (server.DBMS_NAME == 'DB2')
      pattern = expected_zos
    elsif (server.DBMS_NAME[0,3] == 'IDS')
      pattern = expected_ids
    else
      pattern = expected_luw
    end

    '\.[]*?+|(){}^$/'.each_byte { |c| pattern.gsub! c.chr, "\\#{c.chr}" }
    if RUBY_VERSION =~ /1.9/
      pattern.gsub! '%s', '?.*?'
    else
      pattern.gsub! '%s', '.*?'
    end
    pattern.gsub! '%d', '\d+'
    pattern.gsub! "\n", '\n'

    assert_match Regexp.new('^' + pattern + '$'), capture(&block)
  end

  def assert_expectregex &block
    prepconn = IBM_DB::connect database, user, password
    server = IBM_DB::server_info( prepconn )
    IBM_DB::close prepconn
    if (server.DBMS_NAME == 'AS')
      assert_match Regexp.new(expected_systemi), capture(&block)
    elsif (server.DBMS_NAME == 'DB2')
      assert_match Regexp.new(expected_zos), capture(&block)
    elsif (server.DBMS_NAME[0,3] == 'IDS')
      assert_match Regexp.new(expected_ids), capture(&block)
    else
      assert_match Regexp.new(expected_luw), capture(&block)
    end
  end

end
