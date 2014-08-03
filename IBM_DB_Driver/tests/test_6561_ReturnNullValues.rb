# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_6561_ReturnNullValues
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        stmt = IBM_DB::exec conn, "INSERT INTO animals (id, breed, name, weight) VALUES (nil, nil, nil, nil)"
        statement = "SELECT count(id) FROM animals"; 
        result = IBM_DB::exec conn, statement
        if !result && IBM_DB::stmt_error()
          printf("ERROR: %s\n", IBM_DB::stmt_errormsg()); 
        end 
        while (row = IBM_DB::fetch_array(result))
          row.each { |child| puts child }
        end
      
        IBM_DB::rollback conn
        IBM_DB::close conn
        
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
7
__ZOS_EXPECTED__
7
__SYSTEMI_EXPECTED__
7
__IDS_EXPECTED__
7
