# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_211_FieldDisplaySize_02
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from sales"
      
      i=1
      
      while (i <= IBM_DB::num_fields(result))
        printf("%d size %d\n",i, IBM_DB::field_display_size(result,i) || 0)
        i+=1
      end
      
      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
1 size 15
2 size 15
3 size 11
4 size 0
__ZOS_EXPECTED__
1 size 15
2 size 15
3 size 11
4 size 0
__SYSTEMI_EXPECTED__
1 size 15
2 size 15
3 size 11
4 size 0
__IDS_EXPECTED__
1 size 15
2 size 15
3 size 11
4 size 0
