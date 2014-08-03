# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_6792_FieldTypeRetStrDatetimeTimestamp
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        drop = 'DROP TABLE table_6792'
        result = IBM_DB::exec(conn, drop) rescue nil

        server = IBM_DB::server_info( conn )
        if (server.DBMS_NAME[0,3] == 'IDS')
          statement = "CREATE TABLE table_6792 (col1 DATETIME HOUR TO SECOND, col2 DATE, col3 DATETIME YEAR TO SECOND)"
          result = IBM_DB::exec conn, statement
          statement = "INSERT INTO table_6792 (col1, col2, col3) values ('10:42:34', '1981-07-08', '1981-07-08 10:42:34')"
          result = IBM_DB::exec conn, statement
        else
          statement = "CREATE TABLE table_6792 (col1 TIME, col2 DATE, col3 TIMESTAMP)"
          result = IBM_DB::exec conn, statement
          statement = "INSERT INTO table_6792 (col1, col2, col3) values ('10.42.34', '1981-07-08', '1981-07-08-10.42.34')"
          result = IBM_DB::exec conn, statement
        end
        statement = "SELECT * FROM table_6792"
        result = IBM_DB::exec conn, statement
        
        for i in (0 ... IBM_DB::num_fields(result))
          puts "#{i}:#{IBM_DB::field_type(result,i)}"
        end

        statement = "SELECT * FROM table_6792"
        stmt = IBM_DB::prepare conn, statement
        rc = IBM_DB::execute stmt
        while IBM_DB::fetch_row(stmt)
          row0 = IBM_DB::result stmt, 0
          row1 = IBM_DB::result stmt, 1
          row2 = IBM_DB::result stmt, 2
          puts row0
          puts row1
          puts row2
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
0:time
1:date
2:timestamp
10:42:34
1981-07-08
1981-07-08 10:42:34.000000
__ZOS_EXPECTED__
0:time
1:date
2:timestamp
10:42:34
1981-07-08
1981-07-08 10:42:34.000000
__SYSTEMI_EXPECTED__
0:time
1:date
2:timestamp
10:42:34
1981-07-08
1981-07-08 10:42:34.000000
__IDS_EXPECTED__
0:time
1:date
2:timestamp
10:42:34
1981-07-08
1981-07-08 10:42:34.000000
