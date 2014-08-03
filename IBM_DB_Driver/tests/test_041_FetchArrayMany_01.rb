# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_041_FetchArrayMany_01
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::exec conn, "select * from animals order by breed"
      
        i = 0
      
        while( cols = IBM_DB::fetch_array( stmt ) )
          for col in cols
            print "#{col} "
          end
          puts ""
          i+=1
        end
      
        print "\nNumber of rows: #{i}"
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
4 budgerigar Gizmo            0.2E0 
0 cat Pook             0.32E1 
1 dog Peaches          0.123E2 
5 goat Rickety Ride     0.97E1 
3 gold fish Bubbles          0.1E0 
2 horse Smarty           0.35E3 
6 llama Sweater          0.15E3 

Number of rows: 7
__ZOS_EXPECTED__
4 budgerigar Gizmo            0.2E0
0 cat Pook             0.32E1
1 dog Peaches          0.123E2
5 goat Rickety Ride     0.97E1
3 gold fish Bubbles          0.1E0
2 horse Smarty           0.35E3
6 llama Sweater          0.15E3

Number of rows: 7
__SYSTEMI_EXPECTED__
4 budgerigar Gizmo            0.2E0
0 cat Pook             0.32E1
1 dog Peaches          0.123E2
5 goat Rickety Ride     0.97E1
3 gold fish Bubbles          0.1E0
2 horse Smarty           0.35E3
6 llama Sweater          0.15E3

Number of rows: 7
__IDS_EXPECTED__
4 budgerigar Gizmo            0.2E0
0 cat Pook             0.32E1
1 dog Peaches          0.123E2
5 goat Rickety Ride     0.97E1
3 gold fish Bubbles          0.1E0
2 horse Smarty           0.35E3
6 llama Sweater          0.15E3

Number of rows: 7
