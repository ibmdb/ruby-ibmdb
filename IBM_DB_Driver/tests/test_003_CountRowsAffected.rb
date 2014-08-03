# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_003_CountRowsAffected
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
        sql = 'UPDATE animals SET id = 9'
        res = IBM_DB::exec conn, sql
        print "Number of affected rows: #{IBM_DB::num_rows(res)}"
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
Number of affected rows: 7
__ZOS_EXPECTED__
Number of affected rows: 7
__SYSTEMI_EXPECTED__
Number of affected rows: 7
__IDS_EXPECTED__
Number of affected rows: 7
