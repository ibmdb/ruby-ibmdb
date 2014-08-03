# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_065_MetadataWithSearchPattern
    assert_expectf do
      conn = IBM_DB::connect db,user,password
      server = IBM_DB::server_info( conn )

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
      
      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::tables conn, nil, '%', "t3"
      else
        result = IBM_DB::tables conn, nil, '%', "T3"
      end
      
      columns = IBM_DB::num_fields result
      
      for i in (0 ... columns)
        print "#{IBM_DB::field_name(result, i)}, ";    
      end
      print "\n\n"
      
      while (row = IBM_DB::fetch_array(result))
        final = ", " + row[1] + ", " + row[2] + ", " + row[3] + ", , ";
      end

      print final
      
      IBM_DB::free_result result

      IBM_DB::exec(conn, 'DROP TABLE t.t1')
      IBM_DB::exec(conn, 'DROP TABLE t.t2')
      IBM_DB::exec(conn, 'DROP TABLE t.t3')
      IBM_DB::exec(conn, 'DROP TABLE t.t4')
    end
  end

end

__END__
__LUW_EXPECTED__
TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, 

, T, T3, TABLE, ,
__ZOS_EXPECTED__
TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, 

, %sT, T3, TABLE, ,
__SYSTEMI_EXPECTED__
TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, 

, %sT, T3, TABLE, ,
__IDS_EXPECTED__
table_cat, table_schem, table_name, table_type, remarks, 

, %sT%s, t3, TABLE%s, ,
