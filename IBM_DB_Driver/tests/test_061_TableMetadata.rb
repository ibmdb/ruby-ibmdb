# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_061_TableMetadata
    assert_expectf do
      conn = IBM_DB::connect db,username,password

      create = 'CREATE SCHEMA AUTHORIZATION t'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t1( c1 integer, c2 varchar(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t2( c1 integer, c2 varchar(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t3( c1 integer, c2 varchar(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t4( c1 integer, c2 varchar(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      if conn
        server = IBM_DB::server_info( conn )
        if (server.DBMS_NAME[0,3] == 'IDS')
          op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
          IBM_DB::set_option conn, op, 0
        end

        result = IBM_DB::tables(conn,nil,'t'.upcase);    
        i = 0
        while (row = IBM_DB::fetch_both(result))
          str = row['TABLE_SCHEM'] + row['TABLE_NAME'] + row['TABLE_TYPE']
          if (i < 4)
            puts str
          end
          i = i + 1
        end

        IBM_DB::exec(conn, 'DROP TABLE t.t1')
        IBM_DB::exec(conn, 'DROP TABLE t.t2')
        IBM_DB::exec(conn, 'DROP TABLE t.t3')
        IBM_DB::exec(conn, 'DROP TABLE t.t4')

        print "done!"
      else
        print "no connection: #{IBM_DB::conn_errormsg}";    
      end
    end
  end
end

__END__
__LUW_EXPECTED__
TT1TABLE
TT2TABLE
TT3TABLE
TT4TABLE
done!
__ZOS_EXPECTED__
TT1TABLE
TT2TABLE
TT3TABLE
TT4TABLE
done!
__SYSTEMI_EXPECTED__
TT1TABLE
TT2TABLE
TT3TABLE
TT4TABLE
done! 
__IDS_EXPECTED__
T%st1TABLE%s
T%st2TABLE%s
T%st3TABLE%s
T%st4TABLE%s
done! 
