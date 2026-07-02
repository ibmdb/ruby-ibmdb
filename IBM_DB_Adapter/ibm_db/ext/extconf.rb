#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'rubygems/package'
require 'zlib'
require 'fileutils'

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006 - 2024                            |
# +----------------------------------------------------------------------+

TAR_LONGLINK = '././@LongLink'

unless RUBY_PLATFORM =~ /linux/
  puts "This repository builds ibm_db on Linux x86 only. Current platform: #{RUBY_PLATFORM}\n"
  exit 1
end

# use ENV['IBM_DB_HOME'] or latest db2 you can find
IBM_DB_HOME = ENV['IBM_DB_HOME']

machine_bits = ['ibm'].pack('p').size * 8

is64Bit = true

if machine_bits == 64
  is64Bit = true
  puts "Detected 64-bit Ruby\n "
else
  is64Bit = false
  puts "Detected 32-bit Ruby\n "
end

module Kernel
  def suppress_warnings
    origVerbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = origVerbosity
    return result
  end
end

cli_archive_name = ''

if RUBY_PLATFORM =~ /x86_64/
  puts 'Detected platform - linux x86_64'
  cli_archive_name = 'linuxx64_odbc_cli.tar.gz'
elsif RUBY_PLATFORM =~ /i686|i386|-linux$/
  puts 'Detected platform - linux x86 32-bit'
  cli_archive_name = 'linuxia32_odbc_cli.tar.gz'
else
  puts "Unsupported Linux CPU for bundled CLI: #{RUBY_PLATFORM}. Use IBM_DB_HOME with a matching client install.\n"
  exit 1
end

# Каталоги поиска локальных архивов IBM CLI (odbc_cli) при сборке из исходников репозитория.
def local_odbc_cli_search_dirs
  dirs = []
  env_dir = ENV['IBM_DB_ODBC_CLI_DIR']
  dirs << File.expand_path(env_dir) if env_dir && !env_dir.empty?
  dirs << File.expand_path('../../../../odbc_cli', __FILE__)
  dirs << File.expand_path('../../../odbc_cli', __FILE__)
  dirs.uniq
end

# Ищет локальный архив clidriver для текущей платформы; возвращает путь или nil.
def find_local_cli_archive(archive_name)
  return nil if archive_name.nil? || archive_name.empty?

  local_odbc_cli_search_dirs.each do |dir|
    path = File.join(dir, archive_name)
    return path if File.file?(path)
  end
  nil
end

# URL raw-файла на GitHub, если локальный архив недоступен.
def cli_package_download_url(archive_name)
  repo = ENV.fetch('IBM_DB_ODBC_CLI_REPO', 'etspring/ruby-ibmdb')
  branch = ENV.fetch('IBM_DB_ODBC_CLI_BRANCH', 'master')
  "https://raw.githubusercontent.com/#{repo}/#{branch}/odbc_cli/#{archive_name}"
end

# Копирует локальный архив или скачивает clidriver; возвращает путь к архиву в destination.
def obtain_cli_package(destination, cli_archive_name)
  if cli_archive_name.nil? || cli_archive_name.empty?
    raise "CLI driver package is not defined for platform #{RUBY_PLATFORM}"
  end

  filename = File.join(destination, 'clidriver.tar.gz')

  local_archive = find_local_cli_archive(cli_archive_name)
  if local_archive
    puts "Using local CLI package from #{local_archive}\n"
    FileUtils.cp(local_archive, filename)
    return filename
  end

  puts "Local CLI package not found; downloading #{cli_archive_name}\n"
  require 'down'
  Down.download(cli_package_download_url(cli_archive_name), destination: filename, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  filename
end

# Удаляет временный архив clidriver после успешной распаковки в lib/.
def remove_cli_package_archive(archive_path)
  return unless archive_path
  return unless File.file?(archive_path)

  FileUtils.rm_f(archive_path)
  puts "Removed CLI package archive #{archive_path}\n"
end

def untarCLIPackage(archive, destination)
  Gem::Package::TarReader.new(Zlib::GzipReader.open(archive)) do |tar|
    tar.each do |entry|
      file = nil
      if entry.full_name == $TAR_LONGLINK
        file = File.join destination, entry.read.strip
        next
      end
      file ||= File.join destination, entry.full_name
      if entry.directory?
        File.delete file if File.file? file
        FileUtils.mkdir_p file, :mode => entry.header.mode, :verbose => false
      elsif entry.file?
        FileUtils.rm_rf file if File.directory? file
        File.open file, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod entry.header.mode, file, :verbose => false
      elsif entry.header.typeflag == '2' #Symlink!
        FileUtils.rm_f(file)
        File.symlink entry.header.linkname, file
      end
    end
  end
end

if(IBM_DB_HOME == nil || IBM_DB_HOME == '')
  IBM_DB_INCLUDE = ENV['IBM_DB_INCLUDE']
  IBM_DB_LIB = ENV['IBM_DB_LIB']
  
  if( ( (IBM_DB_INCLUDE.nil?) || (IBM_DB_LIB.nil?) ) ||
      ( IBM_DB_INCLUDE == '' || IBM_DB_LIB == '' )
	)
	if(!cli_archive_name.nil? && !cli_archive_name.empty?)
		puts "Environment variable IBM_DB_HOME is not set. Setting up the DB2 client driver from local archive or download\n"
		destination = File.expand_path('../lib', __dir__)
		clidriver_path = File.join(destination, 'clidriver')
		libdb2 = File.join(clidriver_path, 'lib', 'libdb2.so')

		unless File.file?(libdb2) || File.symlink?(libdb2)
    archive = obtain_cli_package(destination, cli_archive_name)
    untarCLIPackage(archive, destination)
    remove_cli_package_archive(archive)
		else
		  puts "CLI driver already present at #{clidriver_path}\n"
		end
	
		IBM_DB_HOME="#{destination}/clidriver"
	
		IBM_DB_INCLUDE = "#{IBM_DB_HOME}/include"
		IBM_DB_LIB="#{IBM_DB_HOME}/lib"
	else
		puts "Environment variable IBM_DB_HOME is not set. Set it to your DB2/IBM_Data_Server_Driver installation directory and retry gem install.\n "
		exit 1
	end
  end
else
  IBM_DB_INCLUDE = "#{IBM_DB_HOME}/include"
  
  if(is64Bit)
    IBM_DB_LIB="#{IBM_DB_HOME}/lib64"
  else
    IBM_DB_LIB="#{IBM_DB_HOME}/lib32"
  end
end

if( !(File.directory?(IBM_DB_LIB)) )
  suppress_warnings{IBM_DB_LIB = "#{IBM_DB_HOME}/lib"}
  if( !(File.directory?(IBM_DB_LIB)) )
    puts "Cannot find #{IBM_DB_LIB} directory. Check if you have set the IBM_DB_HOME environment variable's value correctly\n "
	exit 1
  end
  notifyString  = "Detected usage of IBM Data Server Driver package. Ensure you have downloaded "
  
  if(is64Bit)
    notifyString = notifyString + "64-bit package "
  else
    notifyString = notifyString + "32-bit package "
  end
  notifyString = notifyString + "of IBM_Data_Server_Driver and retry the 'gem install ibm_db' command\n "
  
  puts notifyString
end

if( !(File.directory?(IBM_DB_INCLUDE)) )
  puts " #{IBM_DB_HOME}/include folder not found. Check if you have set the IBM_DB_HOME environment variable's value correctly\n "
  exit 1
end

require 'mkmf'

dir_config('IBM_DB',IBM_DB_INCLUDE,IBM_DB_LIB)

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

if( RUBY_VERSION =~ /1.9/ || RUBY_VERSION =~ /2./ || RUBY_VERSION =~ /3./)
  create_header('gil_release_version.h')
  create_header('unicode_support_version.h')
end

unless have_library('db2', 'SQLConnect') || find_library('db2', 'SQLConnect', IBM_DB_LIB)
  crash(<<EOL)
Unable to locate libdb2.so/a under #{IBM_DB_LIB}

Follow the steps below and retry

Step 1: - Install IBM DB2 Universal Database Server/Client

step 2: - Set the environment variable IBM_DB_HOME as below
        
             (assuming bash shell)
        
             export IBM_DB_HOME=<DB2/IBM_Data_Server_Driver installation directory> #(Eg: export IBM_DB_HOME=/opt/ibm/db2/v10)

step 3: - Retry gem install
        
EOL
end

if RUBY_VERSION =~ /2./ || RUBY_VERSION =~ /3./
  require 'rbconfig'
end

alias :libpathflag0 :libpathflag
def libpathflag(libpath)
  rpaths = libpath[0..-2].map { |path| " -Wl,-rpath,#{path}" }.join
  libpathflag0 + rpaths + " '-Wl,-rpath,$$ORIGIN/clidriver/lib' "
end

have_header('gil_release_version.h')
have_header('unicode_support_version.h')

create_makefile('ibm_db')
