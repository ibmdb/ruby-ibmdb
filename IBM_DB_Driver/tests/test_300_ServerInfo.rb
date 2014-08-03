# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_300_ServerInfo
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      
      server = IBM_DB::server_info conn
      
      if server
        print "DBMS_NAME: ";
        puts "string(#{(server.DBMS_NAME).length}) #{(server.DBMS_NAME).inspect}"
        print "DBMS_VER: ";
        puts "string(#{(server.DBMS_VER).length}) #{(server.DBMS_VER).inspect}"
        print "DB_CODEPAGE: ";
        puts "int(#{server.DB_CODEPAGE})"
        print "DB_NAME: ";
        puts "string(#{(server.DB_NAME).length}) #{(server.DB_NAME).inspect}"
        print "INST_NAME: ";
        puts "string(#{(server.INST_NAME).length}) #{(server.INST_NAME).inspect}"
        print "SPECIAL_CHARS: ";
        puts "string(#{(server.SPECIAL_CHARS).length}) #{(server.SPECIAL_CHARS).inspect}"
        print "KEYWORDS: ";
        puts "int(#{server.KEYWORDS.size})"
        print "DFT_ISOLATION: ";
        puts "string(#{(server.DFT_ISOLATION).length}) #{(server.DFT_ISOLATION).inspect}"
        print "ISOLATION_OPTION: ";         
        il = ''
        for opt in server.ISOLATION_OPTION
          il += opt + " "
        end
        puts "string(#{il.length}) #{il.inspect}"
        print "SQL_CONFORMANCE: ";
        puts "string(#{(server.SQL_CONFORMANCE).length}) #{(server.SQL_CONFORMANCE).inspect}"
        print "PROCEDURES: ";
        puts server.PROCEDURES; 
        print "IDENTIFIER_QUOTE_CHAR: ";
        puts "string(#{(server.IDENTIFIER_QUOTE_CHAR).length}) #{(server.IDENTIFIER_QUOTE_CHAR).inspect}"
        print "LIKE_ESCAPE_CLAUSE: ";
        puts server.LIKE_ESCAPE_CLAUSE; 
        print "MAX_COL_NAME_LEN: ";
        puts "int(#{server.MAX_COL_NAME_LEN})"
        print "MAX_ROW_SIZE: ";
        puts "int(#{server.MAX_ROW_SIZE})"
        print "MAX_IDENTIFIER_LEN: ";
        puts "int(#{server.MAX_IDENTIFIER_LEN})"
        print "MAX_INDEX_SIZE: ";
        puts "int(#{server.MAX_INDEX_SIZE})"
        print "MAX_PROC_NAME_LEN: ";
        puts "int(#{server.MAX_PROC_NAME_LEN})"
        print "MAX_SCHEMA_NAME_LEN: ";
        puts "int(#{server.MAX_SCHEMA_NAME_LEN})"
        print "MAX_STATEMENT_LEN: ";
        puts "int(#{server.MAX_STATEMENT_LEN})"
        print "MAX_TABLE_NAME_LEN: ";
        puts "int(#{server.MAX_TABLE_NAME_LEN})"
        print "NON_NULLABLE_COLUMNS: ";
        puts server.NON_NULLABLE_COLUMNS; 
      
        IBM_DB::close conn
      else
        print "Error."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
DBMS_NAME: string(%d) %s
DBMS_VER: string(%d) %s
DB_CODEPAGE: int(%d)
DB_NAME: string(%d) %s
INST_NAME: string(%d) %s
SPECIAL_CHARS: string(%d) %s
KEYWORDS: int(%d)
DFT_ISOLATION: string(%d) %s
ISOLATION_OPTION: string(%d) %s
SQL_CONFORMANCE: string(%d) %s
PROCEDURES: %s
IDENTIFIER_QUOTE_CHAR: string(%d) %s
LIKE_ESCAPE_CLAUSE: %s
MAX_COL_NAME_LEN: int(%d)
MAX_ROW_SIZE: int(%d)
MAX_IDENTIFIER_LEN: int(%d)
MAX_INDEX_SIZE: int(%d)
MAX_PROC_NAME_LEN: int(%d)
MAX_SCHEMA_NAME_LEN: int(%d)
MAX_STATEMENT_LEN: int(%d)
MAX_TABLE_NAME_LEN: int(%d)
NON_NULLABLE_COLUMNS: %s
__ZOS_EXPECTED__
DBMS_NAME: string(%d) %s
DBMS_VER: string(%d) %s
DB_CODEPAGE: int(%d)
DB_NAME: string(%d) %s
INST_NAME: string(%d) %s
SPECIAL_CHARS: string(%d) %s
KEYWORDS: int(%d)
DFT_ISOLATION: string(%d) %s
ISOLATION_OPTION: string(%d) %s
SQL_CONFORMANCE: string(%d) %s
PROCEDURES: %s
IDENTIFIER_QUOTE_CHAR: string(%d) %s
LIKE_ESCAPE_CLAUSE: %s
MAX_COL_NAME_LEN: int(%d)
MAX_ROW_SIZE: int(%d)
MAX_IDENTIFIER_LEN: int(%d)
MAX_INDEX_SIZE: int(%d)
MAX_PROC_NAME_LEN: int(%d)
MAX_SCHEMA_NAME_LEN: int(%d)
MAX_STATEMENT_LEN: int(%d)
MAX_TABLE_NAME_LEN: int(%d)
NON_NULLABLE_COLUMNS: %s
__SYSTEMI_EXPECTED__
DBMS_NAME: string(%d) %s
DBMS_VER: string(%d) %s
DB_CODEPAGE: int(%d)
DB_NAME: string(%d) %s
INST_NAME: string(%d) %s
SPECIAL_CHARS: string(%d) %s
KEYWORDS: int(%d)
DFT_ISOLATION: string(%d) %s
ISOLATION_OPTION: string(%d) %s
SQL_CONFORMANCE: string(%d) %s
PROCEDURES: %s
IDENTIFIER_QUOTE_CHAR: string(%d) %s
LIKE_ESCAPE_CLAUSE: %s
MAX_COL_NAME_LEN: int(%d)
MAX_ROW_SIZE: int(%d)
MAX_IDENTIFIER_LEN: int(%d)
MAX_INDEX_SIZE: int(%d)
MAX_PROC_NAME_LEN: int(%d)
MAX_SCHEMA_NAME_LEN: int(%d)
MAX_STATEMENT_LEN: int(%d)
MAX_TABLE_NAME_LEN: int(%d)
NON_NULLABLE_COLUMNS: %s
__IDS_EXPECTED__
DBMS_NAME: string(%d) %s
DBMS_VER: string(%d) %s
DB_CODEPAGE: int(%d)
DB_NAME: string(%d) %s
INST_NAME: string(%d) %s
SPECIAL_CHARS: string(%d) %s
KEYWORDS: int(%d)
DFT_ISOLATION: string(%d) %s
ISOLATION_OPTION: string(%d) %s
SQL_CONFORMANCE: string(%d) %s
PROCEDURES: %s
IDENTIFIER_QUOTE_CHAR: string(%d) %s
LIKE_ESCAPE_CLAUSE: %s
MAX_COL_NAME_LEN: int(%d)
MAX_ROW_SIZE: int(%d)
MAX_IDENTIFIER_LEN: int(%d)
MAX_INDEX_SIZE: int(%d)
MAX_PROC_NAME_LEN: int(%d)
MAX_SCHEMA_NAME_LEN: int(%d)
MAX_STATEMENT_LEN: int(%d)
MAX_TABLE_NAME_LEN: int(%d)
NON_NULLABLE_COLUMNS: %s
