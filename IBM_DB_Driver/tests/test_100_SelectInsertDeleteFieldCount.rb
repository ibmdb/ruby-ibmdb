# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_100_SelectInsertDeleteFieldCount
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        stmt = IBM_DB::exec conn, "SELECT * FROM animals ORDER BY breed"
      
        fields1 = IBM_DB::num_fields stmt
        
		puts "int(#{fields1})"
        
        stmt = IBM_DB::exec conn, "SELECT name, breed FROM animals ORDER BY breed"
        fields2 = IBM_DB::num_fields stmt
        
		puts "int(#{fields2})"
        
        stmt = IBM_DB::exec conn, "DELETE FROM animals"
        fields3 = IBM_DB::num_fields stmt
        
		puts "int(#{fields3})"
        
        stmt = IBM_DB::exec conn, "INSERT INTO animals values (0, 'cat', 'Pook', 3.2)"
        fields4 = IBM_DB::num_fields stmt
          
		puts "int(#{fields4})"
        
        stmt = IBM_DB::exec conn, "SELECT name, breed, 'TEST' FROM animals"
        fields5 = IBM_DB::num_fields stmt
          
		puts "int(#{fields5})"

        IBM_DB::rollback conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
int(4)
int(2)
int(0)
int(0)
int(3)
__ZOS_EXPECTED__
int(4)
int(2)
int(0)
int(0)
int(3)
__SYSTEMI_EXPECTED__
int(4)
int(2)
int(0)
int(0)
int(3)
__IDS_EXPECTED__
int(4)
int(2)
int(0)
int(0)
int(3)
