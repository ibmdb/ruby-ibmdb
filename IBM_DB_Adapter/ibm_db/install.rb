# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

module IBM_DB_PrepPlugin
  require 'pathname'
  require 'fileutils'

  # Backup Rails application environment
  def backup_environment
    # Identify config directory while being in ../vendor/plugins/ibm_db/install.rb
    app_root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent
    config_path = app_root + 'config'
    environment = config_path + 'environment.rb'
    if environment.file?
      env_backup = config_path + 'pre_IBM_DB_environment.rb'
      puts "Backup Rails application environment: \n   #{environment} \ninto \n   #{env_backup}"
      FileUtils.cp( environment.to_s, env_backup.to_s )
    end
    environment
  end
end

class IBM_DB_Setup
  include IBM_DB_PrepPlugin

  # Modify Rails environment to bpass ActiveRecord initialization
  # until plugins initialization
  def bypass_ar_initialization
    environment = backup_environment
    puts "Customize Rails environment for IBM_DB plugin:\
\n   #{environment}\
\n.. bypassing ActiveRecord initialization until plugin initialization: "
    env_content = environment.readlines
    File.open(environment,"w") do |enviro|
      env_content.each do |orig_line|
        enviro.puts orig_line
        print "+"
        if orig_line =~ /\sconfig\.frameworks -=/
          enviro.puts "  # IBM_DB: bypass ActiveRecord initialization until plugin initialization"
          enviro.puts "  config.frameworks -= [ :active_record ]"
        end
      end
      puts ".\nIBM_DB plugin is now installed.\n\n"
    end
  end

  def trigger_test
    print "Test IBM_DB plugin:   "
    plugin_root = Pathname.new(File.dirname(__FILE__))
    Dir.chdir "#{plugin_root}"
    
    unless RUBY_PLATFORM =~ /mswin32/
      puts `rake`
    else
      puts `cmd.exe /c rake`
    end
    puts "IBM_DB plugin is now tested.\n\n"
  end
end

setup = IBM_DB_Setup.new
setup.bypass_ar_initialization
setup.trigger_test
