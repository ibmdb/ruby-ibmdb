# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_102_numfieldswithvalues
    assert_expect do
      conn = IBM_DB::connect db, username, password

      if !conn
        print IBM_DB::conn_errormsg
      end
      
      result = IBM_DB::exec conn, "VALUES(1)"
      throw :unsupported unless result
      print IBM_DB::num_fields(result)
      IBM_DB::close conn
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
