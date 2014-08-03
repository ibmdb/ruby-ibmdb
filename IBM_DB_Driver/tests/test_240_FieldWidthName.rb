# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_240_FieldWidthName
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from sales"
      result2 = IBM_DB::exec conn, "select * from staff"
      result3 = IBM_DB::exec conn, "select * from emp_photo"
      
      for i in (0 ... IBM_DB::num_fields(result))
        puts "#{i}:#{IBM_DB::field_width(result,i)}"
      end
      puts "\n-----"
      for i in (0 ... IBM_DB::num_fields(result2))
        puts "#{i}:#{IBM_DB::field_width(result2,IBM_DB::field_name(result2,i))}"
      end
      puts "\n-----"
      for i in (0 ... 3)
        puts "#{i}:#{IBM_DB::field_width(result3,i)},#{IBM_DB::field_display_size(result3,i)}"
      end
      
      puts "\n-----"
      puts "region:#{IBM_DB::field_type(result,'region')}"
      
      puts "5:#{IBM_DB::field_type(result2,5)}"
    end
  end

end

__END__
__LUW_EXPECTED__
0:10
1:15
2:15
3:11

-----
0:6
1:9
2:6
3:5
4:6
5:9
6:9

-----
0:6,6
1:10,10
2:1048576,2097152

-----
region:false
5:real
__ZOS_EXPECTED__
0:10
1:15
2:15
3:11

-----
0:6
1:9
2:6
3:5
4:6
5:9
6:9

-----
0:6,6
1:10,10
2:102400,204800

-----
region:false
5:real
__SYSTEMI_EXPECTED__
0:10
1:15
2:15
3:11

-----
0:6
1:9
2:6
3:5
4:6
5:9
6:9

-----
0:6,6
1:10,10
2:102400,204800

-----
region:false
5:real
__IDS_EXPECTED__
0:10
1:15
2:15
3:11

-----
0:6
1:9
2:6
3:5
4:6
5:9
6:9

-----
0:6,6
1:10,10
2:2147483647,-2

-----
region:string
5:real
