# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_001_CtlgConn
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        print "Connection succeeded."
        IBM_DB::close conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Connection succeeded.
__ZOS_EXPECTED__
Connection succeeded.
__SYSTEMI_EXPECTED__
Connection succeeded.
__IDS_EXPECTED__
Connection succeeded.
