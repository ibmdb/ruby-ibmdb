# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_140_BindParamSelect_01
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::prepare conn, "SELECT id, breed, name, weight FROM animals WHERE id = ?"
      
        animal = 0
        IBM_DB::bind_param stmt, 1, 'animal'
      
        if IBM_DB::execute(stmt)
          while (row = IBM_DB::fetch_array(stmt))
            row.each { |child| puts child }
          end
        end
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
__ZOS_EXPECTED__
0
cat
Pook            
0.32E1
__SYSTEMI_EXPECTED__
0
cat
Pook            
0.32E1
__IDS_EXPECTED__
0
cat
Pook            
0.32E1
