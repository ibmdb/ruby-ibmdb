# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_101_InsertDeleteFieldCount
    assert_expect do
      conn = IBM_DB::connect db,user,password
      if conn
        result = IBM_DB::exec conn,"insert into t_string values(123,1.222333,'one to one')"
        if result
          cols = IBM_DB::num_fields result
          print "col: #{cols}\n"
          rows = IBM_DB::num_rows result
          print "affected row: #{rows }\n"
        end    
        result = IBM_DB::exec conn,"delete from t_string where a=123"
        if result
          cols = IBM_DB::num_fields result
          print "col: #{cols}\n"
          rows = IBM_DB::num_rows result
          print "affected row: #{rows }"
        end    
      else
        print "no connection";    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
col: 0
affected row: 1
col: 0
affected row: 1
__ZOS_EXPECTED__
col: 0
affected row: 1
col: 0
affected row: 1
__SYSTEMI_EXPECTED__
col: 0
affected row: 1
col: 0
affected row: 1 
__IDS_EXPECTED__
col: 0
affected row: 1
col: 0
affected row: 1 
