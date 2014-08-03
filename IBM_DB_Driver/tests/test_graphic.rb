#encoding: UTF-8

#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase
  def test_vargraphic
    assert_expect do
      nameVal = 'praveen𝄞'
      conn = IBM_DB.connect db,username,password

      IBM_DB.exec conn, "drop table graphictest" rescue nil
      IBM_DB.exec conn, "create table graphictest(id integer, name graphic(9))"

      stmt = IBM_DB.prepare conn, "insert into graphictest(id,name) values (1,?)"
      IBM_DB.bind_param stmt, 1, "nameVal"
      IBM_DB.execute stmt

      stmt1 = IBM_DB.exec conn, "select * from graphictest"
      res = IBM_DB.fetch_assoc stmt1

      if( res["NAME"] == nameVal )
        puts "Value retrieved is same as to value inserted"
      else
        puts "Value retrieved is different as to value inserted"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Value retrieved is same as to value inserted
__ZOS_EXPECTED__
Value retrieved is same as to value inserted
__SYSTEMI_EXPECTED__
Value retrieved is same as to value inserted