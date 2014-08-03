# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_213_FieldDisplaySize_04
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::exec conn, "select * from sales"
      
      i = "sales_person"
      
      printf("%s size %d\n",i, IBM_DB::field_display_size(result,i) || 0)
      
      i = "REGION"
      
      printf("%s size %d\n",i, IBM_DB::field_display_size(result,i) || 0)
      
      i = "REgion"
      
      printf("%s size %d\n",i, IBM_DB::field_display_size(result,i) || 0)
      
      i = "HELMUT"
      
      printf("%s size %d\n",i, IBM_DB::field_display_size(result,i) || 0)
      
      t = IBM_DB::field_display_size result,""
      
      puts t
      
      t = IBM_DB::field_display_size result,"HELMUT"
      
      puts t
      
      t = IBM_DB::field_display_size result,"Region"
      
      puts t
      
      t = IBM_DB::field_display_size result,"SALES_DATE"
      
      puts t
    end
  end

end

__END__
__LUW_EXPECTED__
sales_person size 0
REGION size 15
REgion size 0
HELMUT size 0
false
false
false
10
__ZOS_EXPECTED__
sales_person size 0
REGION size 15
REgion size 0
HELMUT size 0
false
false
false
10
__SYSTEMI_EXPECTED__
sales_person size 0
REGION size 15
REgion size 0
HELMUT size 0
false
false
false
10
__IDS_EXPECTED__
sales_person size 15
REGION size 0
REgion size 0
HELMUT size 0
false
false
false
false
