# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS does not support XML as a native datatype (test is invalid for IDS)

class TestIbmDb < Test::Unit::TestCase

  def test_195_InsertRetrieveXmlData
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if (server.DBMS_NAME[0,3] != 'IDS')
        drop = 'DROP TABLE test_195'
        result = IBM_DB::exec(conn, drop) rescue nil
        create = 'CREATE TABLE test_195 (id INTEGER, data XML)'
        result = IBM_DB::exec conn, create
      
        insert = "INSERT INTO test_195 values (0, '<TEST><def><xml/></def></TEST>')"
      
        IBM_DB::exec conn, insert
      
        sql =  "SELECT data FROM test_195"
        stmt = IBM_DB::prepare conn, sql
        IBM_DB::execute stmt
        while(result = IBM_DB::fetch_assoc(stmt))
          print "Output: "
          puts result["DATA"]
        end
        IBM_DB::close conn
      else
        puts "Native XML datatype is not supported by IDS"
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Output:%s<TEST><def><xml/></def></TEST>
__ZOS_EXPECTED__
Output:%s<TEST><def><xml/></def></TEST>
__SYSTEMI_EXPECTED__
N/A
__IDS_EXPECTED__
Native XML datatype is not supported by IDS
