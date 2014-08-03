# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_060_SchemaMetadata
    assert_expectf do
      conn = IBM_DB::connect db,username,password

      create = 'CREATE SCHEMA AUTHORIZATION t'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t1( c1 INTEGER, c2 VARCHAR(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t2( c1 INTEGER, c2 VARCHAR(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t3( c1 INTEGER, c2 VARCHAR(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      create = 'CREATE TABLE t.t4( c1 INTEGER, c2 VARCHAR(40))'
      result = IBM_DB::exec(conn, create) rescue nil
      
      if conn
        result = IBM_DB::tables conn,nil,'t'.upcase
        i = 0
        while (row=IBM_DB::fetch_both(result))
         if (i < 4)
           puts "/#{row[1]}/#{row[2]}"
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
/T/T1
/T/T2
/T/T3
/T/T4
done!
__ZOS_EXPECTED__
/T/T1
/T/T2
/T/T3
/T/T4
done!
__SYSTEMI_EXPECTED__
/T/T1
/T/T2
/T/T3
/T/T4
done! 
__IDS_EXPECTED__
/T%s/t1
/T%s/t2
/T%s/t3
/T%s/t4
done! 
