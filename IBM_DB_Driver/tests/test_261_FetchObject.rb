# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_261_FetchObject
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end

      if (server.DBMS_NAME[0,3] == 'IDS')
        sql = "SELECT breed, TRIM(TRAILING FROM name) AS name FROM animals WHERE id = ?"
      else
        sql = "SELECT breed, RTRIM(name) AS name FROM animals WHERE id = ?"
      end

      if conn
        stmt = IBM_DB::prepare conn, sql
        IBM_DB::execute stmt, [0]
        
        while (pet = IBM_DB::fetch_object(stmt))
          print "Come here, #{pet.NAME}, my little #{pet.BREED}!"
        end
        IBM_DB::close conn
        
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Come here, Pook, my little cat!
__ZOS_EXPECTED__
Come here, Pook, my little cat!
__SYSTEMI_EXPECTED__
Come here, Pook, my little cat!
__IDS_EXPECTED__
Come here, Pook, my little cat!
