# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_064_numfields_fieldnames
    assert_expectf do
      conn = IBM_DB::connect db,user,password

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
      
      result = IBM_DB::tables conn, nil, "T"
      
      for i in (0 ... IBM_DB::num_fields(result))
        print "#{IBM_DB::field_name(result, i)}, ";    
      end
      print "\n\n"
    
      i = 0;
      while (row=IBM_DB::fetch_array(result))
        IBM_DB::num_fields result
        if (i < 4)
          print ", " + row[1] + ", " + row[2] + ", " + row[3] + ", , \n"
        end
        i = i + 1
      end

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

, T, T1, TABLE, , 
, T, T2, TABLE, , 
, T, T3, TABLE, , 
, T, T4, TABLE, ,
__ZOS_EXPECTED__
TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, 

, T, T1, TABLE, , 
, T, T2, TABLE, , 
, T, T3, TABLE, , 
, T, T4, TABLE, ,
__SYSTEMI_EXPECTED__
TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, 

, T, T1, TABLE, , 
, T, T2, TABLE, , 
, T, T3, TABLE, , 
, T, T4, TABLE, ,
__IDS_EXPECTED__
table_cat, table_schem, table_name, table_type, remarks, 

, T%s, t1, TABLE%s, , 
, T%s, t2, TABLE%s, , 
, T%s, t3, TABLE%s, , 
, T%s, t4, TABLE%s, ,
