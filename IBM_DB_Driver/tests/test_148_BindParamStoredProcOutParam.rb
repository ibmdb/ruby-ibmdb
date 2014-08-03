# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_148_BindParamStoredProcOutParam
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        ##### Set up #####
        serverinfo = IBM_DB::server_info( conn )
      	server = serverinfo.DBMS_NAME[0,3]
        sql = "DROP TABLE sptb"
        IBM_DB::exec conn, sql
        sql = "DROP PROCEDURE sp"
        IBM_DB::exec conn, sql
        if (server == 'IDS')
           sql = "CREATE TABLE sptb (c1 INTEGER, c2 FLOAT, c3 VARCHAR(10), c4 INT8, c5 CLOB)"
        else
           sql = "CREATE TABLE sptb (c1 INTEGER, c2 FLOAT, c3 VARCHAR(10), c4 BIGINT, c5 CLOB)"
        end
        IBM_DB::exec conn, sql
        sql = "INSERT INTO sptb (c1, c2, c3, c4, c5) VALUES
              (1, 5.01, 'varchar', 3271982, 'clob data clob data')"
        IBM_DB::exec conn, sql
        if (server == 'IDS')
           sql = "CREATE PROCEDURE sp(OUT out1 INTEGER, OUT out2 FLOAT, OUT out3 VARCHAR(10), OUT out4 INT8, OUT out5 CLOB);
                  SELECT c1, c2, c3, c4, c5 INTO out1, out2, out3, out4, out5 FROM sptb; END PROCEDURE;"
        else
           sql = "CREATE PROCEDURE sp(OUT out1 INTEGER, OUT out2 FLOAT, OUT out3 VARCHAR(10), OUT out4 BIGINT, OUT out5 CLOB)
                  DYNAMIC RESULT SETS 1 LANGUAGE SQL BEGIN
                  SELECT c1, c2, c3, c4, c5 INTO out1, out2, out3, out4, out5 FROM sptb; END"
        end
        IBM_DB::exec conn, sql
        #############################

        ##### Run the test #####
        stmt = IBM_DB::prepare( conn , "CALL sp(?, ?, ?, ?, ?)" )

        out1 = 0
        out2 = 0.00
        out3 = " "*100
        out4 = 0
        out5 = " "*100

        IBM_DB::bind_param( stmt , 1 , "out1" , IBM_DB::SQL_PARAM_OUTPUT )
        IBM_DB::bind_param( stmt , 2 , "out2" , IBM_DB::SQL_PARAM_OUTPUT )
        IBM_DB::bind_param( stmt , 3 , "out3" , IBM_DB::SQL_PARAM_OUTPUT )
        IBM_DB::bind_param( stmt , 4 , "out4" , IBM_DB::SQL_PARAM_OUTPUT )
        IBM_DB::bind_param( stmt , 5 , "out5" , IBM_DB::SQL_PARAM_OUTPUT )

        result = IBM_DB::execute( stmt )

        puts "out 1:"
        puts out1
        puts "out 2:"
        puts out2
        puts "out 3:"
        puts out3
        puts "out 4:"
        puts out4
        puts "out 5:"
        puts out5
        #############################
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
out 1:
1
out 2:
5.01
out 3:
varchar
out 4:
3271982
out 5:
clob data clob data
__ZOS_EXPECTED__
out 1:
1
out 2:
5.01
out 3:
varchar
out 4:
3271982
out 5:
clob data clob data
__SYSTEMI_EXPECTED__
out 1:
1
out 2:
5.01
out 3:
varchar
out 4:
3271982
out 5:
clob data clob data
__IDS_EXPECTED__
out 1:
1
out 2:
5.01
out 3:
varchar
out 4:
3271982
out 5:
clob data clob data
