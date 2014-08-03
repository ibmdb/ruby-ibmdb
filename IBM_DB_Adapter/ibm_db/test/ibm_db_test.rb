require 'test/unit'

class IBM_DBAdapterTest < Test::Unit::TestCase
  require 'pathname'

  # Fixture
  def driver_lib_path
    drv_path = Pathname.new(File.dirname(__FILE__)).parent + 'lib'
    drv_path += (RUBY_PLATFORM =~ /mswin32/) ? 'mswin32' : 'linux32'
    drv_path += 'ibm_db.so'
  end

  # Check IBM_DB Ruby driver for this platform: #{RUBY_PLATFORM}
  def test_driver_existence
    driver = driver_lib_path
    assert driver.file?
  end

  # Attempt loading IBM_DB Ruby driver for this platform: #{RUBY_PLATFORM}
  def test_driver_loading
    driver = driver_lib_path
    require "#{driver.to_s}"
    assert true
  end
end