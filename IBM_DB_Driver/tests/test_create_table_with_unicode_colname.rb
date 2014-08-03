# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_create_table_with_unicode_colname
    assert_expect do
      drop_sql   = "drop table alientab"
      create_sql = "create table alientab(id integer, n𝄞me varchar(20))"

      conn = IBM_DB.connect database, user, password
      IBM_DB.exec conn, drop_sql rescue nil

      stmt = IBM_DB.exec conn, create_sql

      if stmt
        if (IBM_DB.exec conn, "insert into alientab(id, n𝄞me) values (1, 'hey')")
          fetchstmt = IBM_DB.exec conn, "select * from alientab"
	      res = IBM_DB.fetch_assoc fetchstmt
          puts res["N𝄞ME"]
        else
          puts "Insert failed"
        end
      else
        puts "Creation of table Failed"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
hey
__ZOS_EXPECTED__
hey
__SYSTEMI_EXPECTED__
hey
__IDS_EXPECTED__
hey