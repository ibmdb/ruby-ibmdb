# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_040_FetchArray_01
    assert_expect do
      conn = IBM_DB::connect database, user, password

      IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
      
      # Drop the test table, in case it exists
      drop = 'DROP TABLE animals'
      result = IBM_DB::exec(conn, drop) rescue nil
      
      # Create the test table
      create = 'CREATE TABLE animals (id INTEGER, breed VARCHAR(32), name CHAR(16), weight DECIMAL(7,2))'
      result = IBM_DB::exec conn, create
      
      insert = "INSERT INTO animals values (0, 'cat', 'Pook', 3.2)"
      
      IBM_DB::exec conn, insert
      
      stmt = IBM_DB::exec conn, "select * from animals"
      
      onerow = IBM_DB::fetch_array stmt
     
      onerow.each { |child| puts child }

      IBM_DB::rollback conn
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
