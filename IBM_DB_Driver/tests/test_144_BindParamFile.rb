# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_144_BindParamFile
    assert_expect do

      conn = IBM_DB::connect database, user, password
      
      if conn
        # Drop the test table, in case it exists
        drop = 'DROP TABLE pictures'
        result = IBM_DB::exec(conn, drop) rescue nil
        
        # Create the test table
        create = 'CREATE TABLE pictures (id INTEGER, picture BLOB)'
        result = IBM_DB::exec conn, create
        
        stmt = IBM_DB::prepare conn, "INSERT INTO pictures VALUES (0, ?)"
        
        rc = IBM_DB::bind_param stmt, 1, "picture", IBM_DB::SQL_PARAM_INPUT, IBM_DB::SQL_BINARY
        picture = File.dirname(__FILE__) + "/pic1.jpg"
      
        rc = IBM_DB::execute stmt
        
        num = IBM_DB::num_rows stmt
        
        print num
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
1
__ZOS_EXPECTED__
1
__SYSTEMI_EXPECTED__
1
__IDS_EXPECTED__
1
