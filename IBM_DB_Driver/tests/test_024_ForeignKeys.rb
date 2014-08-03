# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS requires that you pass the schema name (cannot pass nil)

class TestIbmDb < Test::Unit::TestCase

  def test_024_ForeignKeys
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn != 0
        drop = 'DROP TABLE test_primary_keys'
        result = IBM_DB::exec(conn, drop) rescue nil
        drop = 'DROP TABLE test_foreign_keys'
        result = IBM_DB::exec(conn, drop) rescue nil
        statement = 'CREATE TABLE test_primary_keys (id INTEGER NOT NULL, PRIMARY KEY(id))'
        result = IBM_DB::exec conn, statement
        statement = "INSERT INTO test_primary_keys VALUES (1)"
        result = IBM_DB::exec conn, statement
        statement = 'CREATE TABLE test_foreign_keys (idf INTEGER NOT NULL, FOREIGN KEY(idf) REFERENCES test_primary_keys(id))'
        result = IBM_DB::exec conn, statement
        statement = "INSERT INTO test_foreign_keys VALUES (1)"
        result = IBM_DB::exec conn, statement
      
        if (server.DBMS_NAME[0,3] == 'IDS')
          stmt = IBM_DB::foreign_keys conn, nil, user, 'test_primary_keys'
        else
          stmt = IBM_DB::foreign_keys conn, nil, nil, 'TEST_PRIMARY_KEYS'
        end
        row = IBM_DB::fetch_array stmt
        puts row[2]
        puts row[3]
        puts row[6]
        puts row[7]
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
TEST_PRIMARY_KEYS
ID
TEST_FOREIGN_KEYS
IDF
__ZOS_EXPECTED__
TEST_PRIMARY_KEYS
ID
TEST_FOREIGN_KEYS
IDF
__SYSTEMI_EXPECTED__
TEST_PRIMARY_KEYS
ID
TEST_FOREIGN_KEYS
IDF
__IDS_EXPECTED__
test_primary_keys
id
test_foreign_keys
idf
