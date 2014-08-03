#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_unicode_xml
    assert_expect do
      if RUBY_VERSION =~ /1.9/
        conn = IBM_DB.connect database,user,password

        unicode_val = "<a>GHRING𝄞</a>"
        IBM_DB.exec conn, "drop table uxmltest"
        IBM_DB.exec conn, "create table uxmltest(id integer, scrap xml)"

        IBM_DB.exec conn, "insert into uxmltest values (1, '#{unicode_val}')"

        stmt = IBM_DB.exec conn, "select * from uxmltest"
        res = IBM_DB.fetch_assoc stmt

        puts res["SCRAP"].size
        puts res["SCRAP"].encoding

        stmt = IBM_DB.exec conn, "select * from uxmltest"
        IBM_DB.fetch_row stmt

        res = IBM_DB.result stmt, 1
        if res =~ /#{unicode_val}/i
          puts "Data Retrieved is same as data inserted"
        else
          puts "Data Retrieved is not same as data inserted"
        end
        puts res.encoding
        IBM_DB.close conn
      else
        puts "53"
        puts "UTF-8"
        puts "Data Retrieved is same as data inserted"
        puts "UTF-8"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
53
UTF-8
Data Retrieved is same as data inserted
UTF-8
__ZOS_EXPECTED__
53
UTF-8
Data Retrieved is same as data inserted
UTF-8
__SYSTEMI_EXPECTED__
53
UTF-8
Data Retrieved is same as data inserted
UTF-8
__IDS_EXPECTED__
53
UTF-8
Data Retrieved is same as data inserted
UTF-8