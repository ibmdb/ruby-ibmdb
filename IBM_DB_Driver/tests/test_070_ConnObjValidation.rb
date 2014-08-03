# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_070_ConnObjValidation
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      
      if conn
        if conn.class == IBM_DB::Connection
          puts "Resource is a DB2 Connection"
        end
        
        rc = IBM_DB::close conn
        
        print rc
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Resource is a DB2 Connection
true
__ZOS_EXPECTED__
Resource is a DB2 Connection
true
__SYSTEMI_EXPECTED__
Resource is a DB2 Connection
true
__IDS_EXPECTED__
Resource is a DB2 Connection
true
