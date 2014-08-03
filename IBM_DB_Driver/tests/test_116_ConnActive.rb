# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_116_ConnActive
    assert_expect do
      conn = nil
      is_alive = IBM_DB::active conn
      if is_alive
        puts "Is active"
      else
        puts "Is not active"
      end

      conn = IBM_DB::connect database, user, password
      is_alive = IBM_DB::active conn
      if is_alive
        puts "Is active"
      else
        puts "Is not active"
      end

      IBM_DB::close conn
      is_alive = IBM_DB::active conn
      if is_alive
        puts "Is active"
      else
        puts "Is not active"
      end

      # Executing active method multiple times to reproduce a customer reported defect
      puts IBM_DB::active(conn)
      puts IBM_DB::active(conn)
      p IBM_DB::active(conn)
      conn = IBM_DB::connect database, user, password
      puts IBM_DB::active(conn)
      puts IBM_DB::active(conn)
      p IBM_DB::active(conn)
      
    end
  end

end

__END__
__LUW_EXPECTED__
Is not active
Is active
Is not active
false
false
false
true
true
true
__ZOS_EXPECTED__
Is not active
Is active
Is not active
false
false
false
true
true
true
__SYSTEMI_EXPECTED__
Is not active
Is active
Is not active
false
false
false
true
true
true
__IDS_EXPECTED__
Is not active
Is active
Is not active
false
false
false
true
true
true
