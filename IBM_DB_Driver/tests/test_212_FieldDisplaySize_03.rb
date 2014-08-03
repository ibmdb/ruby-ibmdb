# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_212_FieldDisplaySize_03
    assert_expect do
      conn = IBM_DB::connect db,user,password
      server = IBM_DB::server_info( conn )

      result = IBM_DB::exec conn, "select * from sales"
      
      if (server.DBMS_NAME[0,3] == 'IDS')
        i = "sales_person"
      else
        i = "SALES_PERSON"
      end
      
      printf("%s size %d\n",i, IBM_DB::field_display_size(result,i))
      
      i=2
      printf("%d size %d\n",i, IBM_DB::field_display_size(result,i))
    end
  end

end

__END__
__LUW_EXPECTED__
SALES_PERSON size 15
2 size 15
__ZOS_EXPECTED__
SALES_PERSON size 15
2 size 15
__SYSTEMI_EXPECTED__
SALES_PERSON size 15
2 size 15
__IDS_EXPECTED__
sales_person size 15
2 size 15
