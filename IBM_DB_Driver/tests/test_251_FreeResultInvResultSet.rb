# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_251_FreeResultInvResultSet
    assert_expect do
      conn = IBM_DB.connect db,user,password

      result99 = nil 
      result = IBM_DB.exec conn, "select * from sales"
      
      r1 = IBM_DB.free_result result
      r2 = IBM_DB.free_result result
      r3 = IBM_DB.free_result(result99)
     
      puts r1
      puts r2
      puts r3
    end
  end

end

__END__
__LUW_EXPECTED__
true
true
false
__ZOS_EXPECTED__
true
true
false
__SYSTEMI_EXPECTED__
true
true
false
__IDS_EXPECTED__
true
true
false
