# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_113_DateTest
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        drop = "DROP TABLE datetest"
        IBM_DB::exec( conn, drop ) rescue nil
        
        create = "CREATE TABLE datetest ( id INTEGER, mydate DATE )"
        IBM_DB::exec conn, create

        server = IBM_DB::server_info( conn )
        if (server.DBMS_NAME[0,3] == 'IDS')
          insert = "INSERT INTO datetest (id, mydate) VALUES (1,'1982-03-27')"
          IBM_DB::exec conn, insert
          insert = "INSERT INTO datetest (id, mydate) VALUES (2,'1981-07-08')"
          IBM_DB::exec conn, insert
        else
          insert = "INSERT INTO datetest (id, mydate) VALUES (1,'1982-03-27')"
          IBM_DB::exec conn, insert
          insert = "INSERT INTO datetest (id, mydate) VALUES (2,'1981-07-08')"
          IBM_DB::exec conn, insert
        end
        
        stmt = IBM_DB::prepare conn, "SELECT * FROM datetest"
        IBM_DB::execute stmt

        while IBM_DB::fetch_row( stmt )
          row0 = IBM_DB::result stmt, 0
          row1 = IBM_DB::result stmt, 1
          puts row0
          puts row1
        end
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
1
1982-03-27
2
1981-07-08
__ZOS_EXPECTED__
1
1982-03-27
2
1981-07-08
__SYSTEMI_EXPECTED__
1
1982-03-27
2
1981-07-08
__IDS_EXPECTED__
1
1982-03-27
2
1981-07-08
