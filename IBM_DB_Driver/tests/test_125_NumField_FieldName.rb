# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_125_NumField_FieldName
    assert_expect do
      conn = IBM_DB::connect db,user,password
      server = IBM_DB::server_info( conn )

      result = IBM_DB::exec conn, "SELECT * FROM sales"
      result2 = IBM_DB::exec conn, "SELECT * FROM staff"
      
      for i in (0 ... IBM_DB::num_fields(result))
        puts "#{i}:#{IBM_DB::field_name(result,i)}"
      end
      
      puts "\n-----"
      
      for i in (0 ... IBM_DB::num_fields(result2))
        puts "#{i}:#{IBM_DB::field_name(result2,i)}"
      end
      
      puts "\n-----"
      
      if (server.DBMS_NAME[0,3] == 'IDS')
        puts "Region:#{IBM_DB::field_name(result,'region')}"
      else
        puts "Region:#{IBM_DB::field_name(result,'REGION')}"
      end
      puts "5:#{IBM_DB::field_name(result2,5)}"
    end
  end

end

__END__
__LUW_EXPECTED__
0:SALES_DATE
1:SALES_PERSON
2:REGION
3:SALES

-----
0:ID
1:NAME
2:DEPT
3:JOB
4:YEARS
5:SALARY
6:COMM

-----
Region:REGION
5:SALARY
__ZOS_EXPECTED__
0:SALES_DATE
1:SALES_PERSON
2:REGION
3:SALES

-----
0:ID
1:NAME
2:DEPT
3:JOB
4:YEARS
5:SALARY
6:COMM

-----
Region:REGION
5:SALARY
__SYSTEMI_EXPECTED__
0:SALES_DATE
1:SALES_PERSON
2:REGION
3:SALES

-----
0:ID
1:NAME
2:DEPT
3:JOB
4:YEARS
5:SALARY
6:COMM

-----
Region:REGION
5:SALARY
__IDS_EXPECTED__
0:sales_date
1:sales_person
2:region
3:sales

-----
0:id
1:name
2:dept
3:job
4:years
5:salary
6:comm

-----
Region:region
5:salary
