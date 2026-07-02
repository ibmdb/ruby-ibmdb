# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006- 2024                             |
# +----------------------------------------------------------------------+

require 'rubygems'
require 'pathname'

Gem::Specification.new do |spec|
  # Required spec
  spec.name     = 'ibm_db'
  spec.version  = '5.5.1'
  spec.summary  = 'Rails driver and adapter for IBM data servers on Linux (DB2, Informix)'

  # Optional spec
  spec.author = 'IBM'
  spec.email = 'opendev@us.ibm.com'
  spec.homepage = 'https://github.com/etspring/ruby-ibmdb'
  spec.required_ruby_version = '>= 2.5.0'
  spec.add_dependency('down')
  spec.add_dependency 'rails', '>= 7.0', '< 7.2'
  spec.add_dependency 'activerecord', '>= 7.0', '< 7.2'

  candidates = Dir.glob("**/*")
  spec.files = candidates.delete_if do |item|
                 item.include?("CVS") ||
                 item.include?("rdoc") ||
                 item.include?("install.rb") ||
                 item.include?("uninstall.rb") ||
                 item.include?("Rakefile") ||
                 item.include?("IBM_DB.gemspec") ||
                 item.include?(".gem") ||
                 item.include?("lib/mswin32") ||
                 item.include?("Makefile.nt32") ||
                 item.end_with?("lib/clidriver.tar.gz") ||
                 item.end_with?("lib/clidriver.zip")
               end

  unless RUBY_PLATFORM =~ /linux/
    raise Gem::InvalidSpecificationException,
          "ibm_db in this repository supports Linux x86 only (current: #{RUBY_PLATFORM})"
  end

  gem_root = File.dirname(__FILE__)
  repo_odbc_cli_dir = File.expand_path('../../odbc_cli', gem_root)
  has_native_sources = File.file?(File.join(gem_root, 'ext', 'ibm_db.c'))
  install_from_local_tree = has_native_sources && File.directory?(repo_odbc_cli_dir)

  puts ".. Check for the pre-built IBM_DB driver for this platform: #{RUBY_PLATFORM}"
  drv_path = Pathname.new(gem_root) + 'lib'
  puts ".. Locate ibm_db driver path: #{drv_path.realpath}"
  drv_lib = drv_path + 'ibm_db.so'
  if install_from_local_tree || ENV['IBM_DB_FORCE_BUILD'] == '1'
    puts ".. Local source tree: ibm_db native extension will be built during install."
    spec.extensions << 'ext/extconf.rb'
  elsif drv_lib.exist? && drv_lib.file? && !drv_lib.symlink?
    puts ".. ibm_db driver was found:   #{drv_lib.realpath}"
  else
    puts ".. ibm_db driver binary was not found. The driver native extension to be built during install."
    spec.extensions << 'ext/extconf.rb'
  end

  spec.test_file = 'test/ibm_db_test.rb'
  spec.extra_rdoc_files = ["CHANGES", "README", "MANIFEST"]
  spec.post_install_message = "\n*****************************************************************************\nSuccessfully installed ibm_db for Linux. CLI driver files are under \"$GEM_HOME/ibm_db-*/lib/clidriver\". License: \"$GEM_HOME/ibm_db-*/lib/clidriver/license\".\n*****************************************************************************\n\n"
end

