# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_112_FieldNumInsertSelect
    assert_expect do
      conn = IBM_DB::connect database, user, password

      if conn
        drop = "DROP TABLE ftest"
        IBM_DB::exec( conn, drop ) rescue nil
        
        create = "CREATE TABLE ftest ( \"TEST\" INTEGER, \"test\" INTEGER, \"Test\" INTEGER  )"
        IBM_DB::exec conn, create
        
        insert = "INSERT INTO ftest VALUES (1,2,3)"
        IBM_DB::exec conn, insert
        
        stmt = IBM_DB::exec conn, "SELECT * FROM ftest"
      
        num1 = IBM_DB::field_num stmt, "TEST"
        num2 = IBM_DB::field_num stmt, 'test'
        num3 = IBM_DB::field_num stmt, 'Test'
        
        puts "int(#{num1})"
        puts "int(#{num2})"
        puts "int(#{num3})"
        
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
int(0)
int(1)
int(2)
__ZOS_EXPECTED__
int(0)
int(1)
int(2)
__SYSTEMI_EXPECTED__
int(0)
int(1)
int(2)
__IDS_EXPECTED__
int(0)
int(1)
int(2)
