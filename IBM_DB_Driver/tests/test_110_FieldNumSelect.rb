# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_110_FieldNumSelect
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn
        stmt = IBM_DB::exec conn, "SELECT * FROM animals ORDER BY breed"
      
        if (server.DBMS_NAME[0,3] == 'IDS')
          num1 = IBM_DB::field_num stmt, "id"
          num2 = IBM_DB::field_num stmt, "breed"
          num3 = IBM_DB::field_num stmt, "name"
          num4 = IBM_DB::field_num stmt, "weight"
          num5 = IBM_DB::field_num stmt, "test"
          num6 = IBM_DB::field_num stmt, 8
          num7 = IBM_DB::field_num stmt, 1
          num8 = IBM_DB::field_num stmt, "WEIGHT"
        else
          num1 = IBM_DB::field_num stmt, "ID"
          num2 = IBM_DB::field_num stmt, "BREED"
          num3 = IBM_DB::field_num stmt, "NAME"
          num4 = IBM_DB::field_num stmt, "WEIGHT"
          num5 = IBM_DB::field_num stmt, "TEST"
          num6 = IBM_DB::field_num stmt, 8
          num7 = IBM_DB::field_num stmt, 1
          num8 = IBM_DB::field_num stmt, "weight"
        end
        
        puts "int(#{num1})"
        puts "int(#{num2})"
        puts "int(#{num3})"
        puts "int(#{num4})"
        
        puts "#{num5}"
        puts "#{num6}"
        puts "int(#{num7})"
        puts "#{num8}"
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
int(0)
int(1)
int(2)
int(3)
false
false
int(1)
false
__ZOS_EXPECTED__
int(0)
int(1)
int(2)
int(3)
false
false
int(1)
false
__SYSTEMI_EXPECTED__
int(0)
int(1)
int(2)
int(3)
false
false
int(1)
false
__IDS_EXPECTED__
int(0)
int(1)
int(2)
int(3)
false
false
int(1)
false
