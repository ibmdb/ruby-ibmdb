# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_015_InsertDeleteRowCount_01
    assert_expect do
      conn = IBM_DB::connect db,username,password
      if conn
        result = IBM_DB::exec conn,"insert into t_string values(123,1.222333,'one to one')"
        if result
          cols = IBM_DB::num_fields result
          print "col: #{cols}\n"
          rows = IBM_DB::num_rows result
          print "affected row: #{rows }\n"
        else
          print "#{IBM_DB::stmt_errormsg}";    
        end
        result = IBM_DB::exec conn,"delete from t_string where a=123"
        if result
          cols = IBM_DB::num_fields result
          print "col: #{cols}\n"
          rows = IBM_DB::num_rows result
          print "affected row: #{rows }"
        else
          print "#{IBM_DB::stmt_errormsg}";    
        end
        IBM_DB::close conn
      else
        print "no connection: #{IBM_DB::conn_errormsg}";    
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
