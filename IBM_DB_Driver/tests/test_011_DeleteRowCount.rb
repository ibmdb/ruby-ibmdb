# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_011_DeleteRowCount
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
        stmt = IBM_DB::exec conn, "DELETE FROM animals WHERE weight > 10.0"
        print "Number of affected rows: #{IBM_DB::num_rows( stmt )}"
        IBM_DB::rollback conn
        IBM_DB::close conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Number of affected rows: 3
__ZOS_EXPECTED__
Number of affected rows: 3
__SYSTEMI_EXPECTED__
Number of affected rows: 3
__IDS_EXPECTED__
Number of affected rows: 3
