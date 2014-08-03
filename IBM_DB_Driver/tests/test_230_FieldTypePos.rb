# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_230_FieldTypePos
    assert_expect do
      conn = IBM_DB::connect db,user,password

      result = IBM_DB::exec conn, "select * from sales"
      result2 = IBM_DB::exec conn, "select * from staff"
      result3 = IBM_DB::exec conn, "select * from emp_photo"
      
      for i in (0 .. IBM_DB::num_fields(result))
        puts "#{i}:#{IBM_DB::field_type(result,i)}"
      end
      puts "\n-----"
      for i in (0 ... IBM_DB::num_fields(result2))
        puts "#{i}:#{IBM_DB::field_type(result2,i)}"
      end
      puts "\n-----"
      for i in (0 ... 3)
        puts "#{i}:#{IBM_DB::field_type(result3,i)}"
      end
      puts "\n-----"
      
      puts "region:#{IBM_DB::field_type(result,'region')}"
      puts "5:#{IBM_DB::field_type(result2,5)}"
    end
  end

end

__END__
__LUW_EXPECTED__
0:date
1:string
2:string
3:int
4:false

-----
0:int
1:string
2:int
3:string
4:int
5:real
6:real

-----
0:string
1:string
2:blob

-----
region:false
5:real
__ZOS_EXPECTED__
0:date
1:string
2:string
3:int
4:false

-----
0:int
1:string
2:int
3:string
4:int
5:real
6:real

-----
0:string
1:string
2:blob

-----
region:false
5:real
__SYSTEMI_EXPECTED__
0:date
1:string
2:string
3:int
4:false

-----
0:int
1:string
2:int
3:string
4:int
5:real
6:real

-----
0:string
1:string
2:blob

-----
region:false
5:real
__IDS_EXPECTED__
0:date
1:string
2:string
3:int
4:false

-----
0:int
1:string
2:int
3:string
4:int
5:real
6:real

-----
0:string
1:string
2:blob

-----
region:string
5:real
