#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'rubygems/package'
require 'zlib'
require 'zip'
require 'fileutils'
require 'down'

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006 - 2024                            |
# +----------------------------------------------------------------------+

TAR_LONGLINK = '././@LongLink'

WIN = RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/

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

DOWNLOADLINK = ''
ZIP = false

if(RUBY_PLATFORM =~ /aix/i)
  #AIX
  if(is64Bit)
        puts "Detected platform - aix 64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/aix64_odbc_cli.tar.gz"
  else
        puts "Detected platform - aix 32"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/aix32_odbc_cli.tar.gz"
  end
elsif (RUBY_PLATFORM =~ /powerpc/ || RUBY_PLATFORM =~ /ppc/)
  #PPC
  if(is64Bit)
        puts "Detected platform - ppc linux 64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/ppc64_odbc_cli.tar.gz"
  else
        puts "Detected platform - ppc linux 64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/ppc32_odbc_cli.tar.gz"
  end
elsif (RUBY_PLATFORM =~ /linux/)
  #x86
  if(is64Bit)
        puts "Detected platform - linux x86 64"
	DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/linuxx64_odbc_cli.tar.gz"
  else
        puts "Detected platform - linux 32"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/linuxia32_odbc_cli.tar.gz"
  end
elsif (RUBY_PLATFORM =~ /sparc/i)
  #Solaris
  if(is64Bit)
        puts "Detected platform - sun sparc64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/sun64_odbc_cli.tar.gz"
  else
        puts "Detected platform - sun sparc32"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/sun32_odbc_cli.tar.gz"
  end
elsif (RUBY_PLATFORM =~ /solaris/i)
  if(is64Bit)
        puts "Detected platform - sun amd64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/sunamd64_odbc_cli.tar.gz"
  else
        puts "Detected platform - sun amd32"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/sunamd32_odbc_cli.tar.gz"
  end
elsif (RUBY_PLATFORM =~ /darwin/i)
  if (RUBY_PLATFORM =~ /arm64/i)
        puts "Detected platform - MacOS darwin arm64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/macarm64_odbc_cli.tar.gz"
  elsif(RUBY_PLATFORM =~ /x86_64/i || is64Bit)
        puts "Detected platform - MacOS darwin x86_64"
        DOWNLOADLINK = "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/macos64_odbc_cli.tar.gz"			
  else
        puts "Mac OS 32 bit not supported. Please use an x64 architecture."
  end
elsif (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)
  ZIP = true
  if(is64Bit)
    puts "Detected platform - windows 64"
    DOWNLOADLINK= "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/ntx64_odbc_cli.zip"
  else
    puts "Detected platform - windows 32"
    DOWNLOADLINK= "https://github.com/etspring/ruby-ibmdb/blob/master/odbc_cli/nt32_odbc_cli.zip"
  end
end

def downloadCLIPackage(destination, link = nil)
  if(link.nil?)
    downloadLink = DOWNLOADLINK
  else
    downloadLink = link
  end

  if ZIP
    filename = "#{destination}/clidriver.zip"
  else
    filename = "#{destination}/clidriver.tar.gz"
  end
  
  Down.download(downloadLink, destination: filename, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)

  filename
end

def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(fpath))
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

def untarCLIPackage(archive,destination)
  Gem::Package::TarReader.new( Zlib::GzipReader.open(archive) ) do |tar|
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
        if (RUBY_PLATFORM =~ /darwin/i) && (RUBY_PLATFORM =~ /arm64/i) && File.exist?(file)
          FileUtils.chmod 755, file, :verbose => false
        end
        File.open file, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod entry.header.mode, file, :verbose => false
      elsif entry.header.typeflag == '2' #Symlink!
        if (RUBY_PLATFORM =~ /darwin/i) && (RUBY_PLATFORM =~ /arm64/i) && File.exist?(file)
           File.delete file if File.file? file
        end
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
	if(!DOWNLOADLINK.nil? && !DOWNLOADLINK.empty?)
		puts "Environment variable IBM_DB_HOME is not set. Downloading and setting up the DB2 client driver\n"
		destination = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/../lib"
	
    archive = downloadCLIPackage(destination)
    if (ZIP)
      extract_zip(archive, destination)
    else 
      untarCLIPackage(archive,destination)
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

unless (have_library(WIN ? 'db2cli' : 'db2','SQLConnect') or find_library(WIN ? 'db2cli' : 'db2','SQLConnect', IBM_DB_LIB))
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

if(RUBY_VERSION =~ /2./ || RUBY_VERSION =~ /3./)
	require 'rbconfig'
end

alias :libpathflag0 :libpathflag
def libpathflag(libpath)
	if(RUBY_PLATFORM =~ /darwin/i)
		if(RUBY_VERSION =~ /2./ || RUBY_VERSION =~ /3./)	
			libpathflag0 + case RbConfig::CONFIG["arch"]	
			when /solaris2/
			  libpath[0..-2].map {|path| " -R#{path}"}.join
			when /linux/
			  libpath[0..-2].map {|path| " -R#{path} "}.join
			else
			  ""
		    end
		else
			libpathflag0 + case Config::CONFIG["arch"]				
			when /solaris2/
			  libpath[0..-2].map {|path| " -R#{path}"}.join
			when /linux/
			  libpath[0..-2].map {|path| " -R#{path} "}.join
			else
			  ""
			end
		end  
	else
		if(RUBY_VERSION =~ /2./ || RUBY_VERSION =~ /3./)	
			ldflags =  case RbConfig::CONFIG["arch"]	
			when /solaris2/
			  libpath[0..-2].map {|path| " -R#{path}"}.join
			when /linux/
			  libpath[0..-2].map {|path| " -R#{path} "}.join
			else
			  ""
		  end
		else
			ldflags =  case Config::CONFIG["arch"]
			when /solaris2/
			  libpath[0..-2].map {|path| " -R#{path}"}.join
			when /linux/
			  libpath[0..-2].map {|path| " -R#{path} "}.join
			else
			  ""
		    end
		end			
		libpathflag0 + " '-Wl,-R$$ORIGIN/clidriver/lib' "		
	end
end

have_header('gil_release_version.h')
have_header('unicode_support_version.h')

create_makefile('ibm_db')
