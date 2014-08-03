# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_034_FetchAssoc
    assert_expect do
      conn = IBM_DB::connect db,user,password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end

      result = IBM_DB::exec conn, "select * from staff"
      
      if row = IBM_DB::fetch_assoc(result)
        printf("%5d  ",row['ID'])
        printf("%-10s ",row['NAME'])
        printf("%5d ",row['DEPT'])
        printf("%-7s ",row['JOB'])
        printf("%5d ", row['YEARS'])
        printf("%15s ", row['SALARY'])
        printf("%10s ", row['COMM'])
        puts ""
      end
      
      
      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
10  Sanders       20 Mgr         7      0.183575E5
__ZOS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575E5
__SYSTEMI_EXPECTED__
10  Sanders       20 Mgr         7      0.183575E5
__IDS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575E5
