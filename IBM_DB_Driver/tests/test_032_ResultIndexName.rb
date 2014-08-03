# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_032_ResultIndexName
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if conn
        stmt = IBM_DB::exec conn, "SELECT id, breed, name, weight FROM animals WHERE id = 6"
        
        while (IBM_DB::fetch_row(stmt) == TRUE)
          if (server.DBMS_NAME[0,3] == 'IDS')
            id = IBM_DB::result stmt, "id"
            breed = IBM_DB::result stmt, "breed"
            name = IBM_DB::result stmt, "name"
            weight = IBM_DB::result stmt, "weight"
          else
            id = IBM_DB::result stmt, "ID"
            breed = IBM_DB::result stmt, "BREED"
            name = IBM_DB::result stmt, "NAME"
            weight = IBM_DB::result stmt, "WEIGHT"
          end
          puts "int(#{id})"
          puts "string(#{breed.length}) #{breed.inspect}"
          puts "string(#{name.length}) #{name.inspect}"
          puts "string(#{weight.length}) #{weight.inspect}"
        end
        IBM_DB::close conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
int(6)
string(5) "llama"
string(16) "Sweater         "
string(6) "150.00"
__ZOS_EXPECTED__
int(6)
string(5) "llama"
string(16) "Sweater         "
string(6) "150.00"
__SYSTEMI_EXPECTED__
int(6)
string(5) "llama"
string(16) "Sweater         "
string(6) "150.00"
__IDS_EXPECTED__
int(6)
string(5) "llama"
string(16) "Sweater         "
string(6) "150.00"
