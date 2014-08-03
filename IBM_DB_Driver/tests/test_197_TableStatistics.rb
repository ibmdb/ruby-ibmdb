# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS requires that you pass the schema name (cannot pass nil)

class TestIbmDb < Test::Unit::TestCase

  def test_197_TableStatistics
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if conn
        rc = IBM_DB::exec(conn, "DROP TABLE index_test")
        rc = IBM_DB::exec(conn, "CREATE TABLE index_test (id INTEGER, data VARCHAR(50))")
        rc = IBM_DB::exec(conn, "CREATE UNIQUE INDEX index1 ON index_test (id)")

        puts "Test first index table:"
        if (server.DBMS_NAME[0,3] == 'IDS')
          result = IBM_DB::statistics(conn,nil,user,"index_test",1)
        else
          result = IBM_DB::statistics(conn,nil,nil,"INDEX_TEST",1)
        end
        row = IBM_DB::fetch_array(result)
        puts row[2]  # TABLE_NAME
        puts row[3]  # NON_UNIQUE
        puts row[5]  # INDEX_NAME
        puts row[8]  # COLUMN_NAME

        rc = IBM_DB::exec(conn, "DROP TABLE index_test2")
        rc = IBM_DB::exec(conn, "CREATE TABLE index_test2 (id INTEGER, data VARCHAR(50))")
        rc = IBM_DB::exec(conn, "CREATE INDEX index2 ON index_test2 (data)")

        puts "Test second index table:"
        if (server.DBMS_NAME[0,3] == 'IDS')
          result = IBM_DB::statistics(conn,nil,user,"index_test2",1)
        else
          result = IBM_DB::statistics(conn,nil,nil,"INDEX_TEST2",1)
        end
        row = IBM_DB::fetch_array(result)
        puts row[2]  # TABLE_NAME
        puts row[3]  # NON_UNIQUE
        puts row[5]  # INDEX_NAME
        puts row[8]  # COLUMN_NAME

        puts "Test non-existent table:"
        if (server.DBMS_NAME[0,3] == 'IDS')
          result = IBM_DB::statistics(conn,nil,user,"non_existent_table",1)
        else
          result = IBM_DB::statistics(conn,nil,nil,"NON_EXISTENT_TABLE",1)
        end
        row = IBM_DB::fetch_array(result)
        if row
          puts "Non-Empty"
        else
          puts "Empty"
        end
      else
        puts 'no connection: ' + IBM_DB::conn_errormsg()
      end

    end
  end

end

__END__
__LUW_EXPECTED__
Test first index table:
INDEX_TEST
0
INDEX1
ID
Test second index table:
INDEX_TEST2
1
INDEX2
DATA
Test non-existent table:
Empty
__ZOS_EXPECTED__
Test first index table:
INDEX_TEST
0
INDEX1
ID
Test second index table:
INDEX_TEST2
1
INDEX2
DATA
Test non-existent table:
Empty
__SYSTEMI_EXPECTED__
Test first index table:
INDEX_TEST
0
INDEX1
nil
Test second index table:
INDEX_TEST2
1
INDEX2
nil
Test non-existent table:
Empty
__IDS_EXPECTED__
Test first index table:
index_test
0
index1
id
Test second index table:
index_test2
1
index2
data
Test non-existent table:
Empty
