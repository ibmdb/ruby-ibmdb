# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_6528_ScopingProblemBindParam
    assert_expect do
      def checked_db2_execute(stmt)
        IBM_DB::execute stmt
        row = IBM_DB::fetch_array stmt
        row.each { |child| puts child }
      end
      
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn
        if (server.DBMS_NAME[0,3] == 'IDS')
          sql = "SELECT TRIM(TRAILING FROM name) FROM animals WHERE breed = ?"
        else
          sql = "SELECT RTRIM(name) FROM animals WHERE breed = ?"
        end
        stmt = IBM_DB::prepare conn, sql
        $var = "cat"
        IBM_DB::bind_param stmt, 1, "$var", IBM_DB::SQL_PARAM_INPUT
        checked_db2_execute(stmt)
        IBM_DB::close conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Pook
__ZOS_EXPECTED__
Pook
__SYSTEMI_EXPECTED__
Pook
__IDS_EXPECTED__
Pook
