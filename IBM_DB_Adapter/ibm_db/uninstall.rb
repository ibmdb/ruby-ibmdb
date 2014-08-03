# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

# Runs only once when the plugin is removed (to remove/restore environment).
require 'pathname'
require 'fileutils'

cpath = Pathname.pwd
env_backup = cpath + 'config' + 'pre_IBM_DB_environment.rb'
if env_backup.file?
  environment = cpath + 'config' + 'environment.rb'
  puts "Restore Rails application environment: \n #{env_backup} \n into \n #{environment}"
  FileUtils.mv( env_backup.to_s, environment.to_s, :force => true )
  puts "IBM_DB plugin is now removed."
else
  puts "Restore failed to recover the pre-IBM_DB environment."
end