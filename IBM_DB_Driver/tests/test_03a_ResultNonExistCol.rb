# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_03a_ResultNonExistCol
    assert_expect do
      conn = IBM_DB.connect database, user, password
      server = IBM_DB.server_info( conn )

      if conn
        stmt = IBM_DB.exec conn, "SELECT id, breed, name, weight FROM animals WHERE id = 0"
        
        while (IBM_DB.fetch_row(stmt) == TRUE)
          breed = IBM_DB.result stmt, 1
          puts "string(#{breed.length}) #{breed.inspect}"
          if (server.DBMS_NAME[0,3] == 'IDS')
            name = IBM_DB.result stmt, "name"
          else
            name = IBM_DB.result stmt, "NAME"
          end
          puts "string(#{name.length}) #{name.inspect}"
      
          # following field does not exist in result set
          name = IBM_DB.result( stmt, "PASSPORT" )
          puts "nil"  if name.nil?
        end
        IBM_DB.close conn
        
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
string(3) "cat"
string(16) "Pook            "
nil
__ZOS_EXPECTED__
string(3) "cat"
string(16) "Pook            "
nil
__SYSTEMI_EXPECTED__
string(3) "cat"
string(16) "Pook            "
nil
__IDS_EXPECTED__
string(3) "cat"
string(16) "Pook            "
nil
