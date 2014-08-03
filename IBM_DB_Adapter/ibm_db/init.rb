# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

require 'pathname'

begin
  puts ".. Attempt to load IBM_DB Ruby driver for IBM Data Servers for this platform: #{RUBY_PLATFORM}"
  unless defined? IBM_DB
    # find IBM_DB driver path relative init.rb
    drv_path = Pathname.new(File.dirname(__FILE__)) + 'lib'
    drv_path += (RUBY_PLATFORM =~ /mswin32/) ? 'mswin32' : 'linux32'
    puts ".. Locate IBM_DB Ruby driver path: #{drv_path}"
    drv_lib = drv_path + 'ibm_db.so'
    require "#{drv_lib.to_s}"
    puts ".. Successfuly loaded IBM_DB Ruby driver: #{drv_lib}"
  end
rescue
  raise LoadError, "Failed to load IBM_DB Driver !?"
end

# Include IBM_DB in the list of supported adapters
RAILS_CONNECTION_ADAPTERS << 'ibm_db'
# load IBM_DB Adapter provided by the plugin
require 'active_record/connection_adapters/ibm_db_adapter'

# Override the frameworks initialization to re-enable ActiveRecord after being
# disabled during plugin install (i.e. config.frameworks -= [ :active_record ])
[:load_environment,\
 :initialize_database,\
 :initialize_logger,\
 :initialize_framework_logging,\
 :initialize_framework_settings,\
 :initialize_framework_views,\
 :initialize_dependency_mechanism,\
 :load_environment ].each do |routine|
  Rails::Initializer.run(routine) do |config|
    config.frameworks = [:active_record]
  end
end