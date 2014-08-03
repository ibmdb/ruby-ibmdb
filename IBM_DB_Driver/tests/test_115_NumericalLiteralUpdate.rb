# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_115_NumericalLiteralUpdate
    assert_expect do
      conn = IBM_DB::connect database, user, password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end
      
      if conn
        drop = "drop table numericliteral"
        IBM_DB::exec( conn, drop ) rescue nil

        create = "create table numericliteral ( id INTEGER, data VARCHAR(50) )"
        IBM_DB::exec conn, create

        insert = "INSERT INTO numericliteral (id, data) values (12, 'NUMERIC LITERAL TEST')"
        IBM_DB::exec conn, insert

        stmt = IBM_DB::prepare conn, "SELECT data FROM numericliteral"
        IBM_DB::execute stmt
        row = IBM_DB::fetch_object stmt, 0
        puts row.DATA

        insert = "UPDATE numericliteral SET data = '@@@@@@@@@@' WHERE id = '12'"
        IBM_DB::exec conn, insert

        stmt = IBM_DB::prepare conn, "SELECT data FROM numericliteral"
        IBM_DB::execute stmt
        row = IBM_DB::fetch_object stmt, 0
        puts row.DATA
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
NUMERIC LITERAL TEST
@@@@@@@@@@
__ZOS_EXPECTED__
NUMERIC LITERAL TEST
@@@@@@@@@@
__SYSTEMI_EXPECTED__
NUMERIC LITERAL TEST
@@@@@@@@@@
__IDS_EXPECTED__
NUMERIC LITERAL TEST
@@@@@@@@@@
