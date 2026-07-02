# frozen_string_literal: true

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

require 'pathname'
require 'fileutils'

# Подготовка окружения Rails перед установкой legacy-плагина ibm_db (vendor/plugins).
module IBM_DB_PrepPlugin # rubocop:disable Naming/ClassAndModuleCamelCase
  # Сохраняет копию config/environment.rb перед правками установщика.
  #
  # Возвращает: Pathname к environment.rb (существующий или ожидаемый путь).
  def backup_environment
    app_root = Pathname.new(__dir__).parent.parent.parent
    config_path = app_root.join('config')
    environment = config_path.join('environment.rb')
    if environment.file?
      env_backup = config_path.join('pre_IBM_DB_environment.rb')
      puts "Backup Rails application environment: \n   #{environment} \ninto \n   #{env_backup}"
      FileUtils.cp(environment.to_s, env_backup.to_s)
    end
    environment
  end
end

# Установка legacy-плагина ibm_db на Linux: патч environment.rb и запуск тестов.
class IBM_DB_Setup # rubocop:disable Naming/ClassAndModuleCamelCase
  include IBM_DB_PrepPlugin

  # Откладывает инициализацию ActiveRecord до загрузки плагина.
  def bypass_ar_initialization
    environment = backup_environment
    puts <<~MSG
      Customize Rails environment for IBM_DB plugin:
         #{environment}
      .. bypassing ActiveRecord initialization until plugin initialization:
    MSG
    rewrite_environment(environment)
    puts ".\nIBM_DB plugin is now installed.\n\n"
  end

  # Запускает rake-тесты плагина из каталога gem.
  def trigger_test
    print 'Test IBM_DB plugin:   '
    Dir.chdir(__dir__) do
      puts `rake`
    end
    puts "IBM_DB plugin is now tested.\n\n"
  end

  private

  def rewrite_environment(environment)
    env_content = environment.readlines
    File.open(environment, 'w') do |enviro|
      env_content.each do |orig_line|
        enviro.puts orig_line
        print '+'
        write_ar_bypass_lines(enviro) if orig_line =~ /\sconfig\.frameworks -=/
      end
    end
  end

  def write_ar_bypass_lines(enviro)
    enviro.puts '  # IBM_DB: bypass ActiveRecord initialization until plugin initialization'
    enviro.puts '  config.frameworks -= [ :active_record ]'
  end
end

unless RUBY_PLATFORM =~ /linux/
  warn "ibm_db install.rb supports Linux only (#{RUBY_PLATFORM})"
  exit 1
end

setup = IBM_DB_Setup.new
setup.bypass_ar_initialization
setup.trigger_test
