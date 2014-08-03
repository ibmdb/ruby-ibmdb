# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_062_TableMetadata_01
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
        schema = 't'.upcase
        result = IBM_DB::tables(conn,nil,schema);    
        i = 0
        while (row = IBM_DB::fetch_both(result))
         str = row[1] + "/" + row[2] + "/" + row[3]
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
T/T1/TABLE
T/T2/TABLE
T/T3/TABLE
T/T4/TABLE
done!
__ZOS_EXPECTED__
T/T1/TABLE
T/T2/TABLE
T/T3/TABLE
T/T4/TABLE
done!
__SYSTEMI_EXPECTED__
T/T1/TABLE
T/T2/TABLE
T/T3/TABLE
T/T4/TABLE
done! 
__IDS_EXPECTED__
T%s/t1/TABLE%s
T%s/t2/TABLE%s
T%s/t3/TABLE%s
T%s/t4/TABLE%s
done! 
