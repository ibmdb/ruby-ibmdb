# frozen_string_literal: true

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

# Восстанавливает config/environment.rb при удалении legacy-плагина ibm_db.
# Используется: запуск из корня Rails-приложения (vendor/plugins), Linux only.

require 'pathname'
require 'fileutils'

unless RUBY_PLATFORM =~ /linux/
  warn "ibm_db uninstall.rb supports Linux only (#{RUBY_PLATFORM})"
  exit 1
end

cpath = Pathname.pwd
env_backup = cpath.join('config', 'pre_IBM_DB_environment.rb')

if env_backup.file?
  environment = cpath.join('config', 'environment.rb')
  puts "Restore Rails application environment: \n #{env_backup} \n into \n #{environment}"
  FileUtils.mv(env_backup.to_s, environment.to_s, force: true)
  puts 'IBM_DB plugin is now removed.'
else
  puts 'Restore failed to recover the pre-IBM_DB environment.'
end
