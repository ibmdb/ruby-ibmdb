# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_154_AllFetches
    assert_expect do
      conn = IBM_DB::connect db,username,password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end

      statement = 'DROP TABLE fetch_test'
      result = IBM_DB::exec conn, statement

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        statement = 'CREATE TABLE fetch_test (col1 VARCHAR(20), col2 CLOB, col3 INTEGER)'
        st0 = "INSERT INTO fetch_test VALUES ('column 0', 'Data in the clob 0', 0)"
        st1 = "INSERT INTO fetch_test VALUES ('column 1', 'Data in the clob 1', 1)"
        st2 = "INSERT INTO fetch_test VALUES ('column 2', 'Data in the clob 2', 2)"
        st3 = "INSERT INTO fetch_test VALUES ('column 3', 'Data in the clob 3', 3)"
      else
        statement = 'CREATE TABLE fetch_test (col1 VARCHAR(20), col2 CLOB(20), col3 INTEGER)'
        st0 = "INSERT INTO fetch_test VALUES ('column 0', 'Data in the clob 0', 0)"
        st1 = "INSERT INTO fetch_test VALUES ('column 1', 'Data in the clob 1', 1)"
        st2 = "INSERT INTO fetch_test VALUES ('column 2', 'Data in the clob 2', 2)"
        st3 = "INSERT INTO fetch_test VALUES ('column 3', 'Data in the clob 3', 3)"
      end
      result = IBM_DB::exec conn, statement

      result = IBM_DB::exec conn, st0
      result = IBM_DB::exec conn, st1
      result = IBM_DB::exec conn, st2
      result = IBM_DB::exec conn, st3

      statement = "SELECT col1, col2 FROM fetch_test"
      result = IBM_DB::prepare conn, statement
      IBM_DB::execute result

      while (row = IBM_DB::fetch_array(result))
        printf("\"%s\" from VARCHAR is %d bytes long, \"%s\" from CLOB is %d bytes long.\n",
                row[0],row[0].length, row[1],row[1].length)
      end

      result = IBM_DB::prepare conn, statement
      IBM_DB::execute result

      while (row = IBM_DB::fetch_assoc(result))
        printf("\"%s\" from VARCHAR is %d bytes long, \"%s\" from CLOB is %d bytes long.\n",
                row['COL1'], row['COL1'].length, row['COL2'], row['COL2'].length)
      end

      result = IBM_DB::prepare conn, statement
      IBM_DB::execute result

      while (row = IBM_DB::fetch_both(result))
        printf("\"%s\" from VARCHAR is %d bytes long, \"%s\" from CLOB is %d bytes long.\n",
                row['COL1'], row['COL1'].length, row[1], row[1].length)
      end

      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
__ZOS_EXPECTED__
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
__SYSTEMI_EXPECTED__
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
__IDS_EXPECTED__
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
"column 0" from VARCHAR is 8 bytes long, "Data in the clob 0" from CLOB is 18 bytes long.
"column 1" from VARCHAR is 8 bytes long, "Data in the clob 1" from CLOB is 18 bytes long.
"column 2" from VARCHAR is 8 bytes long, "Data in the clob 2" from CLOB is 18 bytes long.
"column 3" from VARCHAR is 8 bytes long, "Data in the clob 3" from CLOB is 18 bytes long.
