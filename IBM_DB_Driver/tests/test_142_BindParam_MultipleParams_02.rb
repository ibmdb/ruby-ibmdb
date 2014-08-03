# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_142_BindParam_MultipleParams_02
    assert_expect do
      sql = "SELECT id, breed, name, weight
        FROM animals
        WHERE weight < ? AND weight > ?"
      
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::prepare conn, sql
      
        IBM_DB::bind_param stmt, 1, 'weight', IBM_DB::SQL_PARAM_INPUT
        IBM_DB::bind_param stmt, 2, 'mass', IBM_DB::SQL_PARAM_INPUT
      
        weight = 200.05
        mass = 2.0
      
        if IBM_DB::execute(stmt)
          while (row = IBM_DB::fetch_array(stmt))
            row.each { |child| puts child }
          end
        end
        IBM_DB::close conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
5
goat
Rickety Ride    
0.97E1
6
llama
Sweater         
0.15E3
__ZOS_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
5
goat
Rickety Ride    
0.97E1
6
llama
Sweater         
0.15E3
__SYSTEMI_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
5
goat
Rickety Ride    
0.97E1
6
llama
Sweater         
0.15E3
__IDS_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
5
goat
Rickety Ride    
0.97E1
6
llama
Sweater         
0.15E3
