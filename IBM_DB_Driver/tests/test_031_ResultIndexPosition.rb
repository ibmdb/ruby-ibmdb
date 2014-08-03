# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_031_ResultIndexPosition
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::exec conn, "SELECT id, breed, name, weight FROM animals WHERE id = 0"
        
        while (IBM_DB::fetch_row(stmt) == TRUE)
          id = IBM_DB::result stmt, 0
          puts "int(#{id})"
          breed = IBM_DB::result stmt, 1
          puts "string(#{breed.length}) #{breed.inspect}"
          name = IBM_DB::result stmt, 2
          puts "string(#{name.length}) #{name.inspect}"
          weight = IBM_DB::result stmt, 3
          puts "string(#{weight.length}) #{weight.inspect}"
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
int(0)
string(3) "cat"
string(16) "Pook            "
string(4) "3.20"
__ZOS_EXPECTED__
int(0)
string(3) "cat"
string(16) "Pook            "
string(4) "3.20"
__SYSTEMI_EXPECTED__
int(0)
string(3) "cat"
string(16) "Pook            "
string(4) "3.20"
__IDS_EXPECTED__
int(0)
string(3) "cat"
string(16) "Pook            "
string(4) "3.20"
