if (RUBY_VERSION =~ /1.9/ ) 
  require 'mswin32/rb19x/ibm_db.so'
elsif (RUBY_VERSION =~ /2./ )
  #Check if we are on 64-bit or 32-bit ruby and load binary accordingly
  machine_bits = ['ibm'].pack('p').size * 8
  if machine_bits == 64
    #require 'mswin32/rb2x/x64/ibm_db.so'
	raise NotImplementedError, "ibm_db with Ruby 2.0 64-bit on Windows platform is not supported. Refer to README for more details"
  else
    require 'mswin32/rb2x/i386/ibm_db.so'
  end
else
  require 'mswin32/rb18x/ibm_db.so'
end