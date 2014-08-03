# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_146_BindParamStoredProcInandOutParam
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn
        sql = 'CALL match_animal(?, ?, ?)'
        stmt = IBM_DB::prepare conn, sql
      
        name = "Peaches"
        second_name = "Rickety Ride"
        weight = 0
        IBM_DB::bind_param stmt, 1, "name", IBM_DB::SQL_PARAM_INPUT
        IBM_DB::bind_param stmt, 2, "second_name", IBM_DB::SQL_PARAM_INPUT_OUTPUT
        IBM_DB::bind_param stmt, 3, "weight", IBM_DB::SQL_PARAM_OUTPUT
      
        puts "Values of bound parameters _before_ CALL:"
        print "  1: #{name} 2: #{second_name} 3: #{weight}\n\n"
      
        if IBM_DB::execute(stmt)
          puts "Values of bound parameters _after_ CALL:"
          print "  1: #{name} 2: #{second_name} 3: #{weight}\n\n"

          if (server.DBMS_NAME[0,3] != 'IDS')
            puts "Results:"
            while (row = IBM_DB::fetch_array(stmt))
                print "  #{row[0].strip}, #{row[1].strip}, #{row[2]}\n";    
            end
          end
        end
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Values of bound parameters _before_ CALL:
  1: Peaches 2: Rickety Ride 3: 0

Values of bound parameters _after_ CALL:
  1: Peaches 2: TRUE 3: 12

Results:
  Peaches, dog, 0.123E2
  Pook, cat, 0.32E1
  Rickety Ride, goat, 0.97E1
  Smarty, horse, 0.35E3
  Sweater, llama, 0.15E3
__ZOS_EXPECTED__
Values of bound parameters _before_ CALL:
  1: Peaches 2: Rickety Ride 3: 0

Values of bound parameters _after_ CALL:
  1: Peaches 2: TRUE 3: 12

Results:
  Peaches, dog, 0.123E2
  Pook, cat, 0.32E1
  Rickety Ride, goat, 0.97E1
  Smarty, horse, 0.35E3
  Sweater, llama, 0.15E3
__SYSTEMI_EXPECTED__
Values of bound parameters _before_ CALL:
  1: Peaches 2: Rickety Ride 3: 0

Values of bound parameters _after_ CALL:
  1: Peaches 2: TRUE 3: 12

Results:
  Peaches, dog, 0.123E2
  Pook, cat, 0.32E1
  Rickety Ride, goat, 0.97E1
  Smarty, horse, 0.35E3
  Sweater, llama, 0.15E3
__IDS_EXPECTED__
Values of bound parameters _before_ CALL:
  1: Peaches 2: Rickety Ride 3: 0

Values of bound parameters _after_ CALL:
  1: Peaches 2: TRUE 3: 12

