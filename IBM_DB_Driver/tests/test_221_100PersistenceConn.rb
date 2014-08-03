# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_221_100PersistenceConn
    assert_expect do
      pconn = []
      
      for i in (1 .. 100)
        pconn[i] = IBM_DB::pconnect(database, user, password)
      end
      
      if pconn[33]
        conn = pconn[22]
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
        stmt = IBM_DB::exec pconn[33], "UPDATE animals SET name = 'flyweight' WHERE weight < 10.0"
        print "Number of affected rows: #{IBM_DB::num_rows( stmt )}"
        IBM_DB::rollback conn
        IBM_DB::close pconn[33]
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
