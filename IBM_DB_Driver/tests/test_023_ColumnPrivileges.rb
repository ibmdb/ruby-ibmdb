# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS requires that you pass the schema name (cannot pass nil)
#
# NOTE: IDS will not return any rows from column_privileges unless
#       there have been privileges granted to another user other
#       then the user that is running the script.  This test assumes
#       that no other user has been granted permission and therefore
#       will return no rows.

class TestIbmDb < Test::Unit::TestCase

  def test_023_ColumnPrivileges
    assert_expectf do
      conn = IBM_DB.connect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')
      server = IBM_DB::server_info( conn )

      if conn != 0
        if (server.DBMS_NAME[0,3] == 'IDS')
          stmt = IBM_DB::column_privileges conn, nil, user, 'animals'
        else
          stmt = IBM_DB::column_privileges conn, nil, nil, 'ANIMALS'
        end
        row = IBM_DB::fetch_array stmt
        if row
          puts row[2]
          puts row[3]
          print row[7]
        end
        IBM_DB::close conn
      else
        print IBM_DB::conn_errormsg
        printf("Connection failed\n\n")
      end
    end
  end

end

__END__
__LUW_EXPECTED__
ANIMALS
BREED
YES
__ZOS_EXPECTED__
ANIMALS
BREED
YES
__SYSTEMI_EXPECTED__
ANIMALS
BREED
YES
__IDS_EXPECTED__
