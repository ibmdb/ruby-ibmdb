# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_052_SetAutocommit_01
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      IBM_DB::autocommit conn, 0
      
      ac = IBM_DB::autocommit conn
      
      print ac
    end
  end

end

__END__
__LUW_EXPECTED__
0
__ZOS_EXPECTED__
0
__SYSTEMI_EXPECTED__
0
__IDS_EXPECTED__
0
