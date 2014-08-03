# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_122_FieldNameInsert
    assert_expect do
      conn = IBM_DB::connect database, user, password

      if conn
        drop = "drop table ftest"
        IBM_DB::exec( conn, drop ) rescue nil
        
        create = "create table ftest ( \"TEST\" integer, \"test\" integer, \"Test\" integer  )"
        IBM_DB::exec conn, create
        
        insert = "INSERT INTO ftest values (1,2,3)"
        IBM_DB::exec conn, insert
        
        stmt = IBM_DB::exec conn, "SELECT * FROM ftest"
      
        num1 = IBM_DB::field_name stmt, 0
        num2 = IBM_DB::field_name stmt, 1
        num3 = IBM_DB::field_name stmt, 2
        
        num4 = IBM_DB::field_name stmt, "TEST"
        num5 = IBM_DB::field_name stmt, 'test'
        num6 = IBM_DB::field_name stmt, 'Test'

        puts "string(#{num1.length}) #{num1.inspect}"          
        puts "string(#{num2.length}) #{num2.inspect}"          
        puts "string(#{num3.length}) #{num3.inspect}"          

        puts "string(#{num4.length}) #{num4.inspect}"          
        puts "string(#{num5.length}) #{num5.inspect}"          
        puts "string(#{num6.length}) #{num6.inspect}"          
        
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
string(4) "TEST"
string(4) "test"
string(4) "Test"
string(4) "TEST"
string(4) "test"
string(4) "Test"
__ZOS_EXPECTED__
string(4) "TEST"
string(4) "test"
string(4) "Test"
string(4) "TEST"
string(4) "test"
string(4) "Test"
__SYSTEMI_EXPECTED__
string(4) "TEST"
string(4) "test"
string(4) "Test"
string(4) "TEST"
string(4) "test"
string(4) "Test"
__IDS_EXPECTED__
string(4) "TEST"
string(4) "test"
string(4) "Test"
string(4) "TEST"
string(4) "test"
string(4) "Test"
