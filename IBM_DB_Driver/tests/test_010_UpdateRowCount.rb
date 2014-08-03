# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_010_UpdateRowCount
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
        stmt = IBM_DB::exec conn, "UPDATE animals SET name = 'flyweight' WHERE weight < 10.0"
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
Number of affected rows: 4
__ZOS_EXPECTED__
Number of affected rows: 4
__SYSTEMI_EXPECTED__
Number of affected rows: 4
__IDS_EXPECTED__
Number of affected rows: 4
