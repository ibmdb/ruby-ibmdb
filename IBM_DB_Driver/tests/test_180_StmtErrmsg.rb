# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_180_StmtErrmsg
    assert_expectf do
      conn = IBM_DB.connect db,username,password
      if conn
        result = IBM_DB.exec(conn,"insert int0 t_string values(123,1.222333,'one to one')") rescue nil
        if result
          cols = IBM_DB.num_fields result
          print "col: #{cols},"
          rows = IBM_DB.num_rows result
          print "affected row: #{rows }"
        else
          print "#{IBM_DB.getErrormsg(conn, IBM_DB::DB_CONN)}";    
        end
        result = IBM_DB.exec(conn,"delete from t_string where a=123") rescue nil
        if result
          cols = IBM_DB.num_fields result
          print "col: #{cols},"
          rows = IBM_DB.num_rows result
          print "affected row: #{rows }"
        else
          print "#{IBM_DB.getErrormsg( conn, IBM_DB::DB_CONN)}";    
        end
      
      else
        print "no connection";    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
[IBM][CLI Driver][DB2/%s] SQL0104N  An unexpected token "insert int0 t_string" was found following "BEGIN-OF-STATEMENT".  Expected tokens may include:  "<space>".  SQLSTATE=42601 SQLCODE=-104col: 0,affected row: 0
__ZOS_EXPECTED__
[IBM][CLI Driver][DB2%s] SQL0104N  An unexpected token "INT0" was found following "".  Expected tokens may include:  "INTO".  SQLSTATE=42601 SQLCODE=-104col: 0,affected row: 0
__SYSTEMI_EXPECTED__
[IBM][CLI Driver][AS] SQL0104N  An unexpected token "INT0" was found following "".  Expected tokens may include:  "INTO".  SQLSTATE=42601 SQLCODE=-104col: 0,affected row: 0
__IDS_EXPECTED__
[IBM][CLI Driver][IDS/%s] A syntax error has occurred. SQLCODE=-201col: 0,affected row: 0
