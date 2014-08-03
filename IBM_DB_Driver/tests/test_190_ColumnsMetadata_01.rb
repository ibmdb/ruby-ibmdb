# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS requires that you pass the schema name (cannot pass nil)

class TestIbmDb < Test::Unit::TestCase

  def test_190_ColumnsMetadata_01
    assert_expectf do
      conn = IBM_DB::connect db,username,password
      server = IBM_DB::server_info( conn )

      if conn
        if (server.DBMS_NAME[0,3] == 'IDS')
          result = IBM_DB::columns conn,nil,user,"employee"
        else
          result = IBM_DB::columns conn,nil,nil,"EMPLOYEE"
        end

        while (row = IBM_DB::fetch_array(result))
         str = row[1] + "/" + row[3];    
         puts str
        end
        print "done!"
      else
        print "no connection: #{IBM_DB::conn_errormsg}";    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
%s/EMPNO
%s/FIRSTNME
%s/MIDINIT
%s/LASTNAME
%s/WORKDEPT
%s/PHONENO
%s/HIREDATE
%s/JOB
%s/EDLEVEL
%s/SEX
%s/BIRTHDATE
%s/SALARY
%s/BONUS
%s/COMM
done!
__ZOS_EXPECTED__
%s/EMPNO
%s/FIRSTNME
%s/MIDINIT
%s/LASTNAME
%s/WORKDEPT
%s/PHONENO
%s/HIREDATE
%s/JOB
%s/EDLEVEL
%s/SEX
%s/BIRTHDATE
%s/SALARY
%s/BONUS
%s/COMM
done!
__SYSTEMI_EXPECTED__
%s/EMPNO
%s/FIRSTNME
%s/MIDINIT
%s/LASTNAME
%s/WORKDEPT
%s/PHONENO
%s/HIREDATE
%s/JOB
%s/EDLEVEL
%s/SEX
%s/BIRTHDATE
%s/SALARY
%s/BONUS
%s/COMM
done!
__IDS_EXPECTED__
%s/empno
%s/firstnme
%s/midinit
%s/lastname
%s/workdept
%s/phoneno
%s/hiredate
%s/job
%s/edlevel
%s/sex
%s/birthdate
%s/salary
%s/bonus
%s/comm
done!
