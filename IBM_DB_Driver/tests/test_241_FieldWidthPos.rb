# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_241_FieldWidthPos
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from sales"
      result2 = IBM_DB::exec conn, "select * from staff"
      result3 = IBM_DB::exec conn, "select * from emp_photo"
      
      for i in (0 ... IBM_DB::num_fields(result))
        puts IBM_DB::field_width(result,i)
      end
      puts "\n-----"
      for i in (0 ... IBM_DB::num_fields(result2))
        puts IBM_DB::field_width(result2,IBM_DB::field_name(result2,i))
      end
    end
  end

end

__END__
__LUW_EXPECTED__
10
15
15
11

-----
6
9
6
5
6
9
9
__ZOS_EXPECTED__
10
15
15
11

-----
6
9
6
5
6
9
9
__SYSTEMI_EXPECTED__
10
15
15
11

-----
6
9
6
5
6
9
9
__IDS_EXPECTED__
10
15
15
11

-----
6
9
6
5
6
9
9
