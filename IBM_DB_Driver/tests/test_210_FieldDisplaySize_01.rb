# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_210_FieldDisplaySize_01
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from staff"
      cols = IBM_DB::num_fields result
      
      for i in (0 ... cols)
        size = IBM_DB::field_display_size result,i
        print "col:#{i} and size: #{size}\n";    
      end
      
      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
col:0 and size: 6
col:1 and size: 9
col:2 and size: 6
col:3 and size: 5
col:4 and size: 6
col:5 and size: 9
col:6 and size: 9
__ZOS_EXPECTED__
col:0 and size: 6
col:1 and size: 9
col:2 and size: 6
col:3 and size: 5
col:4 and size: 6
col:5 and size: 9
col:6 and size: 9
__SYSTEMI_EXPECTED__
col:0 and size: 6
col:1 and size: 9
col:2 and size: 6
col:3 and size: 5
col:4 and size: 6
col:5 and size: 9
col:6 and size: 9
__IDS_EXPECTED__
col:0 and size: 6
col:1 and size: 9
col:2 and size: 6
col:3 and size: 5
col:4 and size: 6
col:5 and size: 9
col:6 and size: 9
