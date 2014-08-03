# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS does not support XML as a native datatype (test is invalid for IDS)

class TestIbmDb < Test::Unit::TestCase

  def test_196_Xquery
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if (server.DBMS_NAME[0,3] != 'IDS')
        rc = IBM_DB::exec(conn, "DROP TABLE xml_test")
        rc = IBM_DB::exec(conn, "CREATE TABLE xml_test (id INTEGER, data VARCHAR(50), xmlcol XML)")
        rc = IBM_DB::exec(conn, "INSERT INTO xml_test (id, data, xmlcol) values (1, 'xml test 1', '<address><street>12485 S Pine St.</street><city>Olathe</city><state>KS</state><zip>66061</zip></address>')"); 

        sql =  "SELECT * FROM xml_test"
        stmt = IBM_DB::prepare conn, sql
        IBM_DB::execute stmt
        while(result = IBM_DB::fetch_both(stmt))
            print "Result ID: "
            puts result[0]
            print "Result DATA: "
            puts result[1]
            print "Result XMLCOL: "
            puts result[2]
        end

        sql = "SELECT XMLSERIALIZE(XMLQUERY('for \$i in \$t/address where \$i/city = \"Olathe\" return <zip>{\$i/zip/text()}</zip>' passing c.xmlcol as \"t\") AS CLOB(32k)) FROM xml_test c WHERE id = 1"
        stmt = IBM_DB::prepare conn, sql
        IBM_DB::execute stmt
        while(result = IBM_DB::fetch_both(stmt))
            print "Result from XMLSerialize and XMLQuery: "
            puts result[0]
        end

        sql = "select xmlquery('for \$i in \$t/address where \$i/city = \"Olathe\" return <zip>{\$i/zip/text()}</zip>' passing c.xmlcol as \"t\") from xml_test c where id = 1"
        stmt = IBM_DB::prepare conn, sql
        IBM_DB::execute stmt
        while(result = IBM_DB::fetch_both(stmt))
            print "Result from only XMLQuery: "
            puts result[0]
        end

      else
        puts 'Native XML datatype is not supported by IDS'
      end

    end
  end

end

__END__
__LUW_EXPECTED__
Result ID: 1
Result DATA: xml test 1
Result XMLCOL:%s<address><street>12485 S Pine St.</street><city>Olathe</city><state>KS</state><zip>66061</zip></address>
Result from XMLSerialize and XMLQuery: <zip>66061</zip>
Result from only XMLQuery:%s<zip>66061</zip>
__ZOS_EXPECTED__
Result ID: 1
Result DATA: xml test 1
Result XMLCOL:%s<address><street>12485 S Pine St.</street><city>Olathe</city><state>KS</state><zip>66061</zip></address>
Result from XMLSerialize and XMLQuery: <zip>66061</zip>
Result from only XMLQuery:%s<zip>66061</zip>
__SYSTEMI_EXPECTED__
N/A
__IDS_EXPECTED__
Native XML datatype is not supported by IDS
