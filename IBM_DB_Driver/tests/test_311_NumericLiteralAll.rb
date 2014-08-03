#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_311_NumericLiteralAll
   assert_expect do
    # Make a connection
    conn = IBM_DB::connect database, user, password

    if conn
       IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_ON 

       # Drop the tab_num_literals table, in case it exists
       drop = 'DROP TABLE tab_num_literals'
       result = IBM_DB::exec(conn, drop) rescue nil
       # Create the animal table
       create = "CREATE TABLE tab_num_literals (col1 INTEGER, col2 FLOAT, col3 DECIMAL(7,2))"
       result = IBM_DB::exec conn, create
   
       insert = "INSERT INTO tab_num_literals values ('11.22', '33.44', '55.66')"
       res = IBM_DB::exec conn, insert
       print "Number of inserted rows: #{IBM_DB::num_rows(res)}\n"

       stmt = IBM_DB::prepare conn, "SELECT col1, col2, col3 FROM tab_num_literals WHERE col1 = '11'"
       IBM_DB::execute stmt       
       while (data = IBM_DB::fetch_both stmt)
         puts data[0]
         puts data[1]
         puts data[2]
       end

       sql = "UPDATE tab_num_literals SET col1 = 77 WHERE col2 = '33.44'"
       res = IBM_DB::exec conn, sql
       print "Number of updated rows: #{IBM_DB::num_rows(res)}\n"

       stmt = IBM_DB::prepare conn, "SELECT col1, col2, col3 FROM tab_num_literals WHERE col2 > '33'"
       IBM_DB::execute stmt
       while (data = IBM_DB::fetch_both stmt)
         puts data[0]
         puts data[1]
         puts data[2]
       end

       sql = "DELETE FROM tab_num_literals WHERE col1 > '10.0'"
       res = IBM_DB::exec conn, sql
       print "Number of deleted rows: #{IBM_DB::num_rows(res)}\n"

       stmt = IBM_DB::prepare conn, "SELECT col1, col2, col3 FROM tab_num_literals WHERE col3 < '56'"
       IBM_DB::execute stmt
       while (data = IBM_DB::fetch_both stmt)
         puts data[0]
         puts data[1]
         puts data[2]
       end

       IBM_DB::rollback conn
       IBM_DB::close conn
    end
   end
  end
end

__END__
__LUW_EXPECTED__
Number of inserted rows: 1
11
33.44
0.5566E2
Number of updated rows: 1
77
33.44
0.5566E2
Number of deleted rows: 1
__ZOS_EXPECTED__
Number of inserted rows: 1
11
33.44
0.5566E2
Number of updated rows: 1
77
33.44
0.5566E2
Number of deleted rows: 1
__SYSTEMI_EXPECTED__
Number of inserted rows: 1
11
33.44
0.5566E2
Number of updated rows: 1
77
33.44
0.5566E2
Number of deleted rows: 1
__IDS_EXPECTED__
Number of inserted rows: 1
11
33.44
0.5566E2
Number of updated rows: 1
77
33.44
0.5566E2
Number of deleted rows: 1
