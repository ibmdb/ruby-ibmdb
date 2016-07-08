# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006- 2016                             |
# +----------------------------------------------------------------------+

require 'rubygems'
require 'pathname'

SPEC = Gem::Specification.new do |spec|
  # Required spec
  spec.name     = 'ibm_db'
  spec.version  = '3.0.4'
  spec.summary  = 'Rails Driver and Adapter for IBM Data Servers: {DB2 on Linux/Unix/Windows, DB2 on zOS, DB2 on i5/OS, Informix (IDS)}'

  # Optional spec
  spec.author = 'IBM'
  spec.email = 'opendev@us.ibm.com'
  spec.homepage = 'https://github.com/ibmdb/ruby-ibmdb'
  spec.rubyforge_project = 'rubyibm'
  spec.required_ruby_version = '>= 2.0.0'
  spec.add_dependency('activerecord', '>= 4.2.0')
  spec.requirements << 'ActiveRecord, at least 4.2.0'

  candidates = Dir.glob("**/*")
  spec.files = candidates.delete_if do |item|
                 item.include?("CVS") ||
                 item.include?("rdoc") ||
                 item.include?("install.rb") ||
                 item.include?("uninstall.rb") ||
                 item.include?("Rakefile") ||
                 item.include?("IBM_DB.gemspec") ||
                 item.include?(".gem") ||
                 item.include?("ibm_db_mswin32.rb")
               end

  if RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw/
    spec.platform = Gem::Platform::CURRENT
	spec.add_dependency('archive-zip', '>= 0.7.0')
  else
    spec.files = candidates.delete_if { |item| item.include?("lib/mswin32") }
    puts ".. Check for the pre-built IBM_DB driver for this platform: #{RUBY_PLATFORM}"
    # find ibm_db driver path
    drv_path = Pathname.new(File.dirname(__FILE__)) + 'lib'
    puts ".. Locate ibm_db driver path: #{drv_path.realpath}"
    drv_lib = drv_path + 'ibm_db.so'
    if drv_lib.file? #&& (require "#{drv_lib.to_s}") #Commenting condition check as Ruby-1.9 does not recognize files from local directory
      puts ".. ibm_db driver was found:   #{drv_lib.realpath}"
    else
      puts ".. ibm_db driver binary was not found. The driver native extension to be built during install."	  
		spec.extensions << 'ext/extconf.rb'	  
    end
  end

  spec.test_file = 'test/ibm_db_test.rb'
  spec.has_rdoc = true
  spec.extra_rdoc_files = ["CHANGES", "README", "MANIFEST"]
  spec.post_install_message = "\n*****************************************************************************\nSuccessfully installed ibm_db, the Ruby gem for IBM DB2/Informix.  The Ruby gem is licensed under the MIT License.   The package also includes IBM ODBC and CLI Driver from IBM, which could have been automatically downloaded as the Ruby gem is installed on your system/device.   The license agreement to the IBM driver is available in the folder \"$GEM_HOME/ibm_db-*/lib/clidriver/license\".  Check for additional dependencies, which may come with their own license agreement(s). Your use of the components of the package and dependencies constitutes your acceptance of their respective license agreements.  If you do not accept the terms of any license agreement(s), then delete the relevant component(s) from your system/device.\n*****************************************************************************\n\n"
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end

return SPEC
