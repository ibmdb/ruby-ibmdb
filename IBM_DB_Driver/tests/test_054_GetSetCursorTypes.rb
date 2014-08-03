#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_054_GetSetCursorTypes
    assert_expect do
      conn = IBM_DB::connect database, user, password

      stmt = IBM_DB::exec conn, "SELECT * FROM animals"
      val = IBM_DB::get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
      puts val

      op = {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_FORWARD_ONLY}
      stmt = IBM_DB::exec conn, "SELECT * FROM animals", op
      val = IBM_DB::get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
      puts val

      op = {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
      stmt = IBM_DB::exec conn, "SELECT * FROM animals", op
      val = IBM_DB::get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
      puts val

      op = {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_STATIC}
      stmt = IBM_DB::exec conn, "SELECT * FROM animals", op
      val = IBM_DB::get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
      puts val
    end
  end

end

__END__
__LUW_EXPECTED__
0
0
1
3
__ZOS_EXPECTED__
0
0
1
3
__SYSTEMI_EXPECTED__
0
0
1
3
__IDS_EXPECTED__
0
0
3
3

