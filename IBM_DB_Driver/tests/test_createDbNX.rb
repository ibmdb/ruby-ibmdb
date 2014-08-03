# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2012
#

class TestIbmDb < Test::Unit::TestCase

  def test_createDbNX
    assert_expect do
      dbToCreate = "crtdb"
      conn_attach_str = "ATTACH=true;UID=#{user};PWD=#{password};"
	  
      #Attach to the instance where database is to be created
      ins_conn = IBM_DB.connect conn_attach_str, '', ''
      
      if ins_conn
        puts "Instance attachment for creation successful"

        #Create database crtdb
        if( IBM_DB.createDBNX ins_conn,dbToCreate )
          puts "Database creation successful"

          #On successful creation try connectiing to the newly created database
          begin
            conn = IBM_DB.connect dbToCreate, user, password
            puts "Connection to newly created database is successful"
            IBM_DB.close conn
          rescue StandardError => e
            puts "Connection to created database failed: #{e}"
          end

          # Try creating the database again. It should return true (as creation only on non existence)
          if(IBM_DB.createDBNX ins_conn,dbToCreate)
            puts "CreateDBNX succeeded"
          else
            puts "CreateDBNX failed: #{IBM_DB.getErrormsg ins_conn, IBM_DB::DB_CONN}"
          end
        else
          puts "Database creation failed: #{IBM_DB.getErrormsg ins_conn, IBM_DB::DB_CONN}"
        end

        #Drop the database crtdb
        if( IBM_DB.dropDB ins_conn,dbToCreate )
          puts "Database drop successful"
        else
          puts "Database drop failed: #{IBM_DB.getErrormsg ins_conn, IBM_DB::DB_CONN}"
        end
      end
      IBM_DB.close ins_conn
    end
  end
end

__END__
__LUW_EXPECTED__
Instance attachment for creation successful
Database creation successful
Connection to newly created database is successful
CreateDBNX succeeded
Database drop successful
