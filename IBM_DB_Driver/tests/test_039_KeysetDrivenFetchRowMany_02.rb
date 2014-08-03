# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_039_KeysetDrivenFetchRowMany_02
    assert_expect do
      conn = IBM_DB::connect db,user,password

      result = IBM_DB::prepare conn, "SELECT * FROM animals", {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
      IBM_DB::execute result
      while (row = IBM_DB::fetch_row(result))
        result2 = IBM_DB::prepare conn, "SELECT * FROM animals", {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
        IBM_DB::execute result2
        while (IBM_DB::fetch_row(result2))
          printf("%s : %s : %s : %s\n", IBM_DB::result(result2, 0),
                                        IBM_DB::result(result2, 1),
                                        IBM_DB::result(result2, 2),
                                        IBM_DB::result(result2, 3))
        end
      end
    end
  end
end

__END__
__LUW_EXPECTED__
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
__ZOS_EXPECTED__
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
__SYSTEMI_EXPECTED__
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
__IDS_EXPECTED__
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
0 : cat : Pook             : 3.20
1 : dog : Peaches          : 12.30
2 : horse : Smarty           : 350.00
3 : gold fish : Bubbles          : 0.10
4 : budgerigar : Gizmo            : 0.20
5 : goat : Rickety Ride     : 9.70
6 : llama : Sweater          : 150.00
