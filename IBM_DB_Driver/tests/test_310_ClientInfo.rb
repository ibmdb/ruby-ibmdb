# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_310_ClientInfo
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      
      client = IBM_DB::client_info conn
      
      if client
        print "DRIVER_NAME: ";
        puts "string(#{(client.DRIVER_NAME).length}) #{(client.DRIVER_NAME).inspect}"
        print "DRIVER_VER: ";
        puts "string(#{(client.DRIVER_VER).length}) #{(client.DRIVER_VER).inspect}"
        print "DATA_SOURCE_NAME: ";
        puts "string(#{(client.DATA_SOURCE_NAME).length}) #{(client.DATA_SOURCE_NAME).inspect}"
        print "DRIVER_ODBC_VER: ";
        puts "string(#{(client.DRIVER_ODBC_VER).length}) #{(client.DRIVER_ODBC_VER).inspect}"
        print "ODBC_VER: ";
        puts "string(#{(client.ODBC_VER).length}) #{(client.ODBC_VER).inspect}"
        print "ODBC_SQL_CONFORMANCE: ";
        puts "string(#{(client.ODBC_SQL_CONFORMANCE).length}) #{(client.ODBC_SQL_CONFORMANCE).inspect}"
        print "APPL_CODEPAGE: ";
        puts "int(#{client.APPL_CODEPAGE})"
        print "CONN_CODEPAGE: ";
        puts "int(#{client.CONN_CODEPAGE})"
      
        IBM_DB::close conn
      else
        print "Error."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
DRIVER_NAME: string(%d) %s
DRIVER_VER: string(%d) %s
DATA_SOURCE_NAME: string(%d) %s
DRIVER_ODBC_VER: string(%d) %s
ODBC_VER: string(%d) %s
ODBC_SQL_CONFORMANCE: string(%d) %s
APPL_CODEPAGE: int(%d)
CONN_CODEPAGE: int(%d)
__ZOS_EXPECTED__
DRIVER_NAME: string(%d) %s
DRIVER_VER: string(%d) %s
DATA_SOURCE_NAME: string(%d) %s
DRIVER_ODBC_VER: string(%d) %s
ODBC_VER: string(%d) %s
ODBC_SQL_CONFORMANCE: string(%d) %s
APPL_CODEPAGE: int(%d)
CONN_CODEPAGE: int(%d)
__SYSTEMI_EXPECTED__
DRIVER_NAME: string(%d) %s
DRIVER_VER: string(%d) %s
DATA_SOURCE_NAME: string(%d) %s
DRIVER_ODBC_VER: string(%d) %s
ODBC_VER: string(%d) %s
ODBC_SQL_CONFORMANCE: string(%d) %s
APPL_CODEPAGE: int(%d)
CONN_CODEPAGE: int(%d)
__IDS_EXPECTED__
DRIVER_NAME: string(%d) %s
DRIVER_VER: string(%d) %s
DATA_SOURCE_NAME: string(%d) %s
DRIVER_ODBC_VER: string(%d) %s
ODBC_VER: string(%d) %s
ODBC_SQL_CONFORMANCE: string(%d) %s
APPL_CODEPAGE: int(%d)
CONN_CODEPAGE: int(%d)
