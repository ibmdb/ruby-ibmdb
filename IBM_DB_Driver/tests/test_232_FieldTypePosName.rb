# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_232_FieldTypePosName
    assert_expect do
      conn = IBM_DB::connect db,user,password

      result = IBM_DB::exec conn, "select * from sales"
      
      for i in (0 .. IBM_DB::num_fields(result))
        puts "#{IBM_DB::field_name(result,i)}:#{IBM_DB::field_type(result,IBM_DB::field_name(result,i))}"
      end
      puts "-----"
      
      t = IBM_DB::field_type result,99
      puts t
      
      t1 = IBM_DB::field_type result, "HELMUT"
      puts t1
    end
  end

end

__END__
__LUW_EXPECTED__
SALES_DATE:date
SALES_PERSON:string
REGION:string
SALES:int
false:false
-----
false
false
__ZOS_EXPECTED__
SALES_DATE:date
SALES_PERSON:string
REGION:string
SALES:int
false:false
-----
false
false
__SYSTEMI_EXPECTED__
SALES_DATE:date
SALES_PERSON:string
REGION:string
SALES:int
false:false
-----
false
false
__IDS_EXPECTED__
sales_date:date
sales_person:string
region:string
sales:int
false:false
-----
false
false
