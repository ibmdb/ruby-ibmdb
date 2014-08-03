# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_006_NormalConn_CursorTypes
    assert_expect do
      options1 = {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
      options2 = {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_SCROLL_FORWARD_ONLY}
      
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::prepare conn, "SELECT name FROM animals WHERE weight < 10.0", options2
        IBM_DB::execute stmt
        while (data = IBM_DB::fetch_both stmt)
          puts data[0]
        end
        
        puts ""
      
        stmt = IBM_DB::prepare conn, "SELECT name FROM animals WHERE weight < 10.0", options1
        IBM_DB::execute stmt
        while (data = IBM_DB::fetch_both stmt)
          puts data[0]
        end
      
        IBM_DB::close conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Pook            
Bubbles         
Gizmo           
Rickety Ride    

Pook            
Bubbles         
Gizmo           
Rickety Ride
__ZOS_EXPECTED__
Pook            
Bubbles         
Gizmo           
Rickety Ride    

Pook            
Bubbles         
Gizmo           
Rickety Ride
__SYSTEMI_EXPECTED__
Pook            
Bubbles         
Gizmo           
Rickety Ride    

Pook            
Bubbles         
Gizmo           
Rickety Ride
__IDS_EXPECTED__
Pook            
Bubbles         
Gizmo           
Rickety Ride    

Pook            
Bubbles         
Gizmo           
Rickety Ride
