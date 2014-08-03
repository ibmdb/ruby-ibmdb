# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_141_BindParam_MultipleParams_01
    assert_expect do
      sql = "SELECT id, breed, name, weight
        FROM animals
        WHERE id < ? AND weight > ?"
      
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::prepare conn, sql
      
        animal = 5
        mass = 2.0
        IBM_DB::bind_param stmt, 1, 'animal'
        IBM_DB::bind_param stmt, 2, 'mass'
      
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
2
horse
Smarty          
0.35E3
__ZOS_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
2
horse
Smarty          
0.35E3
__SYSTEMI_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
2
horse
Smarty          
0.35E3
__IDS_EXPECTED__
0
cat
Pook            
0.32E1
1
dog
Peaches         
0.123E2
2
horse
Smarty          
0.35E3
