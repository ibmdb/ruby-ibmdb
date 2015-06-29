if(RUBY_PLATFORM =~ /darwin/i)
   cliPackagePath = File.dirname(__FILE__)  + '/clidriver'
        if(Dir.exists?(cliPackagePath))
                currentPath = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"

                cmd = "chmod 755 #{currentPath}/lib/ibm_db.bundle "
                `#{cmd}`

                cmd = "chmod 755 #{currentPath}/lib/clidriver/lib/libdb2.dylib"
                `#{cmd}`

                cmd = "install_name_tool -change libdb2.dylib #{currentPath}/lib/clidriver/lib/libdb2.dylib #{currentPath}/lib/ibm_db.bundle"
                `#{cmd}`

                $LOAD_PATH.unshift("#{currentPath}/lib")
        end

        require 'ibm_db.bundle'

elsif(RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/ )
        require 'mswin32/ibm_db'
else
        require 'ibm_db.so'
end

require 'active_record'
require 'active_record/connection_adapters/ibm_db_adapter'
