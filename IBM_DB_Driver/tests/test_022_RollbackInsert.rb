# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_022_RollbackInsert
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows
        
        IBM_DB::autocommit conn, 0
        ac = IBM_DB::autocommit conn
        if ac != 0
          puts "Cannot set IBM_DB::AUTOCOMMIT_OFF\nCannot run test"
          next
        end
        
        IBM_DB::exec conn, "INSERT INTO animals values (7,'bug','Brain Bug',10000.1)"
        
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows
        
        IBM_DB::rollback conn
        
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows
        IBM_DB::close conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
7
8
7
__ZOS_EXPECTED__
7
8
7
__SYSTEMI_EXPECTED__
7
8
7
__IDS_EXPECTED__
7
8
7
