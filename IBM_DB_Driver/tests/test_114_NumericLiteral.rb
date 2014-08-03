# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_114_NumericLiteral
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        drop = "drop table numericliteral"
        IBM_DB::exec( conn, drop ) rescue nil
        
        create = "create table numericliteral ( id INTEGER, num INTEGER )"
        IBM_DB::exec conn, create
        
        insert = "INSERT INTO numericliteral (id, num) values (1,5)"
        IBM_DB::exec conn, insert

        insert = "UPDATE numericliteral SET num = '10' WHERE num = '5'"
        IBM_DB::exec conn, insert
        
        stmt = IBM_DB::prepare conn, "SELECT * FROM numericliteral"
        IBM_DB::execute stmt

        while IBM_DB::fetch_row( stmt )
          row0 = IBM_DB::result stmt, 0
          row1 = IBM_DB::result stmt, 1
          puts row0
          puts row1
        end
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
1
10
__ZOS_EXPECTED__
1
10
__SYSTEMI_EXPECTED__
1
10
__IDS_EXPECTED__
1
10
