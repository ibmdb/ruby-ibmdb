# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_071_CloseConn
    assert_expect do
      conn = IBM_DB::connect db, username, password
      
      if conn
        rc = IBM_DB::close conn
        if rc == true
         puts "IBM_DB::close succeeded"
        else
         print "IBM_DB::close FAILED\n"
        end
      else
        print "#{IBM_DB::conn_errormsg}";    
        print ",sqlstate=#{IBM_DB::conn_error}"
        print "#{IBM_DB::conn_errormsg}";    
        print "#{IBM_DB::conn_errormsg}";    
        print "#{IBM_DB::conn_errormsg}";    
        print "#{IBM_DB::conn_errormsg}";    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
IBM_DB::close succeeded
__ZOS_EXPECTED__
IBM_DB::close succeeded
__SYSTEMI_EXPECTED__
IBM_DB::close succeeded
__IDS_EXPECTED__
IBM_DB::close succeeded
