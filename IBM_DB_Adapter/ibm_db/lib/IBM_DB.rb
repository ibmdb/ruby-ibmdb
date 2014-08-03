require (RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/ ) ? 'mswin32/ibm_db' : 'ibm_db.so'
require 'active_record'
require 'active_record/connection_adapters/ibm_db_adapter'
