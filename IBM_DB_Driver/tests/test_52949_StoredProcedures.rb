# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def int_test conn
    sql = "CALL PROCESSINT(?)"
    stmt = IBM_DB::prepare conn, sql
    return_value = 0
    IBM_DB::bind_param stmt, 1, "return_value", IBM_DB::SQL_PARAM_OUTPUT
    IBM_DB::execute(stmt)
    print "ProcessINT: "
    puts return_value
  end

  def varchar_test conn
    sql = "CALL PROCESSVAR(?)"
    stmt = IBM_DB::prepare conn, sql
    return_value = ""
    IBM_DB::bind_param stmt, 1, "return_value", IBM_DB::SQL_PARAM_OUTPUT, IBM_DB::SQL_CHAR, nil, nil, 4
    IBM_DB::execute(stmt)
    print "ProcessVAR: "
    puts return_value
  end

  def xml_test conn
    sql = "CALL PROCESSXML(?)"
    stmt = IBM_DB::prepare conn, sql
    return_value = ""
    IBM_DB::bind_param stmt, 1, "return_value", IBM_DB::SQL_PARAM_OUTPUT, IBM_DB::SQL_XML, nil, nil, 100
    IBM_DB::execute(stmt)
    print "ProcessXML: "
    puts return_value
  end

  def test_52949_StoredProcedures
    assert_expectf do
      conn = IBM_DB::connect database, user, password

      if conn
        serverinfo = IBM_DB::server_info( conn )
        server = serverinfo.DBMS_NAME[0,3]
        dr = "DROP PROCEDURE processxml"
        result = IBM_DB::exec conn, dr rescue nil
        dr = "DROP PROCEDURE processint"
        result = IBM_DB::exec conn, dr rescue nil
        dr = "DROP PROCEDURE processvar"
        result = IBM_DB::exec conn, dr rescue nil
        dr = "DROP TABLE test_stored"
        result = IBM_DB::exec conn, dr rescue nil

        begin
          cr1 = "CREATE TABLE test_stored (id INT, name VARCHAR(50), age int, cv XML)"
          result = IBM_DB::exec conn, cr1
          in1 = "INSERT INTO test_stored values (1, 'Kellen', 24, '<example>This is an example</example>')"
          result = IBM_DB::exec conn, in1
          st1 = "CREATE PROCEDURE processxml(OUT risorsa xml) LANGUAGE SQL BEGIN SELECT cv INTO risorsa FROM test_stored WHERE ID = 1; END"
          result = IBM_DB::exec conn, st1

          xml_test conn
        rescue
  	      cr1 = "CREATE TABLE test_stored (id INT, name VARCHAR(50), age int, cv VARCHAR(200))"
          result = IBM_DB::exec conn, cr1
          in1 = "INSERT INTO test_stored values (1, 'Kellen', 24, '<example>This is an example</example>')"
          result = IBM_DB::exec conn, in1
        end

        if (server == 'IDS')
           st2 = "CREATE PROCEDURE processint(OUT risorsa int); SELECT age INTO risorsa FROM test_stored WHERE ID = 1; END PROCEDURE;"
        else
           st2 = "CREATE PROCEDURE processint(OUT risorsa int) LANGUAGE SQL BEGIN SELECT age INTO risorsa FROM test_stored WHERE ID = 1; END"
        end
        result = IBM_DB::exec conn, st2
        
        if (server == 'IDS')
           st3 = "CREATE PROCEDURE processvar(OUT risorsa varchar(50)); SELECT name INTO risorsa FROM test_stored WHERE ID = 1; END PROCEDURE;"
        else
           st3 = "CREATE PROCEDURE processvar(OUT risorsa varchar(50)) LANGUAGE SQL BEGIN SELECT name INTO risorsa FROM test_stored WHERE ID = 1; END"
        end
        result = IBM_DB::exec conn, st3

        int_test conn
        varchar_test conn

        IBM_DB::close conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
ProcessXML:%s<example>This is an example</example>
ProcessINT: 24
ProcessVAR: Kell
__ZOS_EXPECTED__
ProcessXML:%s<example>This is an example</example>
ProcessINT: 24
ProcessVAR: Kell
__SYSTEMI_EXPECTED__
ProcessINT: 24
ProcessVAR: Kell
__IDS_EXPECTED__
ProcessINT: 24
ProcessVAR: Kell
