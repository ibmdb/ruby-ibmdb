# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_157a_OutofRangeFetch
    assert_expect do
      conn = IBM_DB.connect db,username,password
      server = IBM_DB.server_info( conn )

      puts "Starting..."
      if conn
        sql = "SELECT id, name, breed, weight FROM animals ORDER BY breed"
        result = IBM_DB.exec conn, sql

        begin
          i=2
          while (row = IBM_DB.fetch_assoc(result, i))
            if (server.DBMS_NAME[0,3] == 'IDS')
              printf("%-5d %-16s %-32s %10s\n", row['id'], row['name'], row['breed'], row['weight'])
            else
              printf("%-5d %-16s %-32s %10s\n", row['ID'], row['NAME'], row['BREED'], row['WEIGHT'])
            end
            i = i + 2
          end
        rescue
          puts "SQLSTATE: #{IBM_DB.getErrorstate(result, IBM_DB::DB_STMT)}"
          puts "Message: #{IBM_DB.getErrormsg(result, IBM_DB::DB_STMT)}"
        end
        print "DONE"
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Starting...
SQLSTATE: HY106
Message: [IBM][CLI Driver] CLI0145E  Fetch type out of range. SQLSTATE=HY106 SQLCODE=-99999
DONE
__ZOS_EXPECTED__
Starting...
SQLSTATE: HY106
Message: [IBM][CLI Driver] CLI0145E  Fetch type out of range. SQLSTATE=HY106 SQLCODE=-99999
DONE
__SYSTEMI_EXPECTED__
Starting...
SQLSTATE: HY106
Message: [IBM][CLI Driver] CLI0145E  Fetch type out of range. SQLSTATE=HY106 SQLCODE=-99999
DONE
__IDS_EXPECTED__
Starting...
SQLSTATE: HY106
Message: [IBM][CLI Driver] CLI0145E  Fetch type out of range. SQLSTATE=HY106 SQLCODE=-99999
DONE
