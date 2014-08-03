# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_051_SetAutocommit
    assert_expect do
      options = { IBM_DB::SQL_ATTR_AUTOCOMMIT => IBM_DB::SQL_AUTOCOMMIT_OFF }
      
      conn = IBM_DB::connect database, user, password, options
      
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
