# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_157b_FetchAssocSelect
    assert_expect do
      conn = IBM_DB.connect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')
      server = IBM_DB::server_info( conn )

      if conn
        sql = "SELECT id, name, breed, weight FROM animals ORDER BY breed"
        stmt = IBM_DB::prepare conn, sql, {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_KEYSET_DRIVEN}
        result = IBM_DB::execute stmt
        i=2
        while (row = IBM_DB::fetch_assoc(stmt, i))
          if (server.DBMS_NAME[0,3] == 'IDS')
            printf("%-5d %-16s %-32s %10s\n", row['id'], row['name'], row['breed'], row['weight'])
          else
            printf("%-5d %-16s %-32s %10s\n", row['ID'], row['NAME'], row['BREED'], row['WEIGHT'])
          end
          i = i + 2
        end
      end
    end
  end
end

__END__
__LUW_EXPECTED__
0     Pook             cat                                  0.32e1
5     Rickety Ride     goat                                 0.97e1
2     Smarty           horse                                   350
__ZOS_EXPECTED__
0     Pook             cat                                  0.32e1
5     Rickety Ride     goat                                 0.97e1
2     Smarty           horse                                   350
__SYSTEMI_EXPECTED__
0     Pook             cat                                  0.32e1
5     Rickety Ride     goat                                 0.97e1
2     Smarty           horse                                   350
__IDS_EXPECTED__
0     Pook             cat                                  0.32e1
5     Rickety Ride     goat                                 0.97e1
2     Smarty           horse                                   350
