# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_250_FreeResult
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from sales"
      result2 = IBM_DB::exec conn, "select * from staff"
      result3 = IBM_DB::exec conn, "select * from emp_photo"
      
      r1 = IBM_DB::free_result result
      r2 = IBM_DB::free_result result2
      r3 = IBM_DB::free_result result3
      
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
true
__ZOS_EXPECTED__
true
true
true
__SYSTEMI_EXPECTED__
true
true
true
__IDS_EXPECTED__
true
true
true
