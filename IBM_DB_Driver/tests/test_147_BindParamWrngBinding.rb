# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_147_BindParamWrngBinding
    assert_expect do
      conn = IBM_DB.connect database, user, password
      
      if conn
        IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        stmt = IBM_DB.prepare conn, "INSERT INTO animals (id, breed, name) VALUES (?, ?, ?)"
      
        id = "\"999\""
        breed = nil
        name = 'RubyDB2'
        IBM_DB.bind_param stmt, 1, 'id'
        IBM_DB.bind_param stmt, 2, 'breed'
        IBM_DB.bind_param stmt, 3, 'name'
         
        # After this statement, we expect that the BREED column will contain
        # an SQL NULL value, while the NAME column contains an empty string
        
        error = IBM_DB.execute(stmt)
        if error
          puts "Statement executed successfully"
        else
          puts "Statement Execute Failed: #{IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)}"
        end
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Statement Execute Failed: [IBM][CLI Driver] CLI0112E  Error in assignment. SQLSTATE=22005 SQLCODE=-99999
__ZOS_EXPECTED__
Statement Execute Failed: [IBM][CLI Driver] CLI0112E  Error in assignment. SQLSTATE=22005 SQLCODE=-99999
__SYSTEMI_EXPECTED__
Statement Execute Failed: [IBM][CLI Driver] CLI0112E  Error in assignment. SQLSTATE=22005 SQLCODE=-99999
__IDS_EXPECTED__
Statement Execute Failed: [IBM][CLI Driver] CLI0112E  Error in assignment. SQLSTATE=22005 SQLCODE=-99999
