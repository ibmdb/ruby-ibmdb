# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_6755_ExtraNullChar_ResultCLOBCol
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn
        drop = 'DROP TABLE table_6755'
        result = IBM_DB::exec(conn, drop) rescue nil

        if (server.DBMS_NAME[0,3] == 'IDS')
          create = 'CREATE TABLE table_6755 (col1 VARCHAR(20), col2 CLOB)'
          insert = "INSERT INTO table_6755 VALUES ('database', 'database')"
        else
          create = 'CREATE TABLE table_6755 (col1 VARCHAR(20), col2 CLOB(20))'
          insert = "INSERT INTO table_6755 VALUES ('database', 'database')"
        end
        result = IBM_DB::exec conn, create
        result = IBM_DB::exec conn, insert
        statement = "SELECT col1, col2 FROM table_6755"
      
        result = IBM_DB::prepare conn, statement
        IBM_DB::execute result
      
        while (row = IBM_DB::fetch_array(result))
          printf("\"%s\" from VARCHAR is %d bytes long, \"%s\" from CLOB is %d bytes long.\n",
              row[0], row[0].length,
              row[1], row[1].length)
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
"database" from VARCHAR is 8 bytes long, "database" from CLOB is 8 bytes long.
__ZOS_EXPECTED__
"database" from VARCHAR is 8 bytes long, "database" from CLOB is 8 bytes long.
__SYSTEMI_EXPECTED__
"database" from VARCHAR is 8 bytes long, "database" from CLOB is 8 bytes long.
__IDS_EXPECTED__
"database" from VARCHAR is 8 bytes long, "database" from CLOB is 8 bytes long.
