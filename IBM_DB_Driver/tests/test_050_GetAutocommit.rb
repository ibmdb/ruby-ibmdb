# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_050_GetAutocommit
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      ac = IBM_DB::autocommit conn
      
      print ac
    end
  end

end

__END__
__LUW_EXPECTED__
1
__ZOS_EXPECTED__
1
__SYSTEMI_EXPECTED__
1
__IDS_EXPECTED__
1
