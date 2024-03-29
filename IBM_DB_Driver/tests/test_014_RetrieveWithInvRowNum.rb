# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_014_RetrieveWithInvRowNum
    assert_expect do
      conn = IBM_DB.connect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')

      query = 'SELECT * FROM animals ORDER BY name'

      stmt = IBM_DB::prepare conn, query, {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
      IBM_DB::execute stmt
      while (data = IBM_DB::fetch_both stmt)
        printf("%s : %s : %s : %s\n", data[0], data[1], data[2], data[3]);
      end

      begin
        stmt = IBM_DB::prepare conn, query, {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
        IBM_DB::execute stmt
        rc = IBM_DB::fetch_row stmt,-1
        printf( "\nFetch row -1: %s\n", rc ? "true" : "false" )
      rescue
        puts "Requested row number must be a positive value"
      end
        
      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
3 : gold fish : Bubbles          : 0.1e0
4 : budgerigar : Gizmo            : 0.2e0
1 : dog : Peaches          : 0.123e2
0 : cat : Pook             : 0.32e1
5 : goat : Rickety Ride     : 0.97e1
2 : horse : Smarty           : 350
6 : llama : Sweater          : 150
Requested row number must be a positive value
__ZOS_EXPECTED__
3 : gold fish : Bubbles          : 0.1e0
4 : budgerigar : Gizmo            : 0.2e0
1 : dog : Peaches          : 0.123e2
0 : cat : Pook             : 0.32e1
5 : goat : Rickety Ride     : 0.97e1
2 : horse : Smarty           : 350
6 : llama : Sweater          : 150
Requested row number must be a positive value
__SYSTEMI_EXPECTED__
3 : gold fish : Bubbles          : 0.1e0
4 : budgerigar : Gizmo            : 0.2e0
1 : dog : Peaches          : 0.123e2
0 : cat : Pook             : 0.32e1
5 : goat : Rickety Ride     : 0.97e1
2 : horse : Smarty           : 350
6 : llama : Sweater          : 150
Requested row number must be a positive value
__IDS_EXPECTED__
3 : gold fish : Bubbles          : 0.1e0
4 : budgerigar : Gizmo            : 0.2e0
1 : dog : Peaches          : 0.123e2
0 : cat : Pook             : 0.32e1
5 : goat : Rickety Ride     : 0.97e1
2 : horse : Smarty           : 350
6 : llama : Sweater          : 150
Requested row number must be a positive value
