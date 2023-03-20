needToDownloadedCLIPackage = false
IBM_DB_HOME = ENV['IBM_DB_HOME']
cliPackagePath = File.dirname(__FILE__)  + '/../clidriver'

if ((IBM_DB_HOME == nil || IBM_DB_HOME == '') && (!Dir.exists?(cliPackagePath)))
   needToDownloadedCLIPackage = true
end

def downloadCLIPackage(destination, link = nil)
	if(link.nil?)
		downloadLink = DOWNLOADLINK
	else
		downloadLink = link
	end

	uri = URI.parse(downloadLink)	
	
	filename = "#{destination}/clidriver.zip"  
	
	headers = { 'Accept-Encoding' => 'identity', }

	request = Net::HTTP::Get.new(uri.request_uri, headers)
	http = Net::HTTP.new(uri.host, uri.port)
	response = http.request(request)

	f = open(filename, 'wb')
	f.write(response.body)
	f.close()

	filename
end

def unzipCLIPackage(archive, destination)
	if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)
		Archive::Zip.extract(archive, destination)	
	end
end		


# Download CLI package 
if(needToDownloadedCLIPackage == true)
	require 'net/http'
	require 'open-uri'
	require 'rubygems/package'
	require 'fileutils'
	require 'archive/zip'

	TAR_LONGLINK = '././@LongLink'	

	machine_bits = ['ibm'].pack('p').size * 8

	is64Bit = true

	if machine_bits == 64
	  is64Bit = true	  
	else
	  is64Bit = false	  
	end

	if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)
	  if(is64Bit)			
			DOWNLOADLINK = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/ntx64_odbc_cli.zip"
	  else			
			DOWNLOADLINK = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/nt32_odbc_cli.zip"			
	  end   
	end
	
	destination = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"	
	archive = downloadCLIPackage(destination)				
	unzipCLIPackage(archive,destination)
end


if(IBM_DB_HOME !=nil && IBM_DB_HOME != '')    
	bin_path = IBM_DB_HOME+'/bin'	
	ENV['PATH'] = ENV['PATH'] + ';.;' + bin_path
end

if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)
	$LOAD_PATH.unshift("#{File.dirname(__FILE__)}")			
	ENV['PATH'] = ENV['PATH'] + ';.;' + File.expand_path(File.dirname(__FILE__) + '/../clidriver/bin')
end		


#Check if we are on 64-bit or 32-bit ruby and load binary accordingly
machine_bits = ['ibm'].pack('p').size * 8
if machine_bits == 64		
	raise NotImplementedError, "ibm_db with Ruby 64-bit on Windows platform is not supported. Refer to README for more details"
else
	if (RUBY_VERSION =~ /3/)
		require 'rb3x/i386/ruby30/ibm_db.so'
	elsif (RUBY_VERSION =~ /2.7/)
		require 'rb2x/i386/ruby27/ibm_db.so'
	elsif (RUBY_VERSION =~ /2.6/)
		require 'rb2x/i386/ruby26/ibm_db.so'
	else
		require 'rb2x/i386/ruby25/ibm_db.so'
	end
end	