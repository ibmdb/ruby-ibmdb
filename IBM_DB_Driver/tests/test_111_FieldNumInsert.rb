# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_111_FieldNumInsert
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        insert = "INSERT INTO animals values (7, 'cat', 'Benji', 5.1)"
        IBM_DB::exec conn, insert
        
        stmt = IBM_DB::exec conn, "SELECT breed, COUNT(breed) AS number FROM animals GROUP BY breed ORDER BY breed"
      
        if (server.DBMS_NAME[0,3] == 'IDS')
          num1 = IBM_DB::field_num stmt, "id"
          num2 = IBM_DB::field_num stmt, "breed"
          num3 = IBM_DB::field_num stmt, "number"
          num4 = IBM_DB::field_num stmt, "NUMBER"
          num5 = IBM_DB::field_num stmt, "bREED"
          num6 = IBM_DB::field_num stmt, 8
          num7 = IBM_DB::field_num stmt, 1
          num8 = IBM_DB::field_num stmt, "WEIGHT"
        else
          num1 = IBM_DB::field_num stmt, "ID"
          num2 = IBM_DB::field_num stmt, "BREED"
          num3 = IBM_DB::field_num stmt, "NUMBER"
          num4 = IBM_DB::field_num stmt, "number"
          num5 = IBM_DB::field_num stmt, "Breed"
          num6 = IBM_DB::field_num stmt, 8
          num7 = IBM_DB::field_num stmt, 1
          num8 = IBM_DB::field_num stmt, "weight"
        end
    
        puts "#{num1}"
        puts "int(#{num2})"
        puts "int(#{num3})"
        puts "#{num4}"
        
        puts "#{num5}"
        puts "#{num6}"
        puts "int(#{num7})"
        puts "#{num8}"

        IBM_DB::rollback conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
false
int(0)
int(1)
false
false
false
int(1)
false
__ZOS_EXPECTED__
false
int(0)
int(1)
false
false
false
int(1)
false
__SYSTEMI_EXPECTED__
false
int(0)
int(1)
false
false
false
int(1)
false
__IDS_EXPECTED__
false
int(0)
int(1)
false
false
false
int(1)
false
