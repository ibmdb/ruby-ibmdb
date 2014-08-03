# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_008_RetrieveMetadataWithDiffAttrCase
    assert_expect do
      op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_NATURAL}
      conn = IBM_DB::connect database, user, password, op
      server = IBM_DB::server_info( conn )

      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::columns conn,nil,nil,"employee"
      else
        result = IBM_DB::columns conn,nil,nil,"EMPLOYEE"
      end
      row = IBM_DB::fetch_both(result)
      puts row['TABLE_NAME']  if row['TABLE_NAME']
      puts row['COLUMN_NAME'] if row['COLUMN_NAME']
      puts "---------"
      puts row['table_name']  if row['table_name']
      puts row['column_name'] if row['column_name']
      puts "---------"

      op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
      IBM_DB::set_option conn, op, 0
      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::columns conn,nil,nil,"employee"
      else
        result = IBM_DB::columns conn,nil,nil,"EMPLOYEE"
      end
      row = IBM_DB::fetch_both(result)
      puts row['TABLE_NAME']  if row['TABLE_NAME']
      puts row['COLUMN_NAME'] if row['COLUMN_NAME']
      puts "---------"
      puts row['table_name']  if row['table_name']
      puts row['column_name'] if row['column_name']
      puts "---------"

      op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_LOWER}
      IBM_DB::set_option conn, op, 0
      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::columns conn,nil,nil,"employee"
      else
        result = IBM_DB::columns conn,nil,nil,"EMPLOYEE"
      end
      row = IBM_DB::fetch_both(result)
      puts row['TABLE_NAME']  if row['TABLE_NAME']
      puts row['COLUMN_NAME'] if row['COLUMN_NAME']
      puts "---------"
      puts row['table_name']  if row['table_name']
      puts row['column_name'] if row['column_name']
      puts "---------"
    end
  end

end

__END__
__LUW_EXPECTED__
EMPLOYEE
EMPNO
---------
---------
EMPLOYEE
EMPNO
---------
---------
---------
EMPLOYEE
EMPNO
---------
__ZOS_EXPECTED__
EMPLOYEE
EMPNO
---------
---------
EMPLOYEE
EMPNO
---------
---------
---------
EMPLOYEE
EMPNO
---------
__SYSTEMI_EXPECTED__
EMPLOYEE
EMPNO
---------
---------
EMPLOYEE
EMPNO
---------
---------
---------
EMPLOYEE
EMPNO
---------
__IDS_EXPECTED__
---------
employee
empno
---------
employee
empno
---------
---------
employee
empno
---------
