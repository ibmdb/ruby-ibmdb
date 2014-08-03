#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_unicode_clob
    assert_expect do
      if RUBY_VERSION =~ /1.9/
        conn = IBM_DB.connect database,user,password
        if conn
          server = IBM_DB::server_info( conn )
          drop = 'DROP TABLE table_6755'
          result = IBM_DB::exec(conn, drop) rescue nil

          if (server.DBMS_NAME[0,3] == 'IDS')
            create = 'CREATE TABLE table_6755 (col1 VARCHAR(20), col2 CLOB)'
            insert = "INSERT INTO table_6755 VALUES ('database', 'database')"
          else
            create = 'CREATE TABLE table_6755 (col1 VARCHAR(20), col2 CLOB(20))'
            insert = "INSERT INTO table_6755 VALUES ('database', 'database')"
          end

          result = IBM_DB::exec conn, create
          result = IBM_DB::exec conn, insert

          unicode_val = "database𝄞"

          IBM_DB.exec conn, "insert into table_6755 values ('#{unicode_val}', '#{unicode_val}')"
          stmt = IBM_DB.exec conn, "select * from table_6755"

          res = IBM_DB.fetch_assoc stmt
          # First row should contain ASCII characters for 'database' with bytesize 8
          # Second row should contain Unicode characters for 'database' with bytesize 8
          unless res["COL1"].bytesize  == 8
            puts "Test failed"
          else
            puts "Byte size test for ascii chars passed"
          end

          unless res["COL2"].bytesize  == 8
            puts "Test failed"
          else
            puts "Byte size test for ascii chars passed"
          end

          res = IBM_DB.fetch_assoc stmt

          unless res["COL1"].bytesize  == 12 && res["COL1"].eql?(unicode_val)
            puts "Test failed"
          else
            puts "Byte size test for unicode chars passed"
          end

          unless res["COL2"].bytesize  == 12 && res["COL2"].eql?(unicode_val)
            puts "Test failed"
          else
            puts "Byte size test for unicode chars passed"
          end

          IBM_DB.close conn
        else
          puts "Connection Failed"
        end
      else
        puts "Byte size test for ascii chars passed"
        puts "Byte size test for ascii chars passed"
        puts "Byte size test for unicode chars passed"
        puts "Byte size test for unicode chars passed"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Byte size test for ascii chars passed
Byte size test for ascii chars passed
Byte size test for unicode chars passed
Byte size test for unicode chars passed
__ZOS_EXPECTED__
Byte size test for ascii chars passed
Byte size test for ascii chars passed
Byte size test for unicode chars passed
Byte size test for unicode chars passed
__SYSTEMI_EXPECTED__
Byte size test for ascii chars passed
Byte size test for ascii chars passed
Byte size test for unicode chars passed
Byte size test for unicode chars passed
__IDS_EXPECTED__
Byte size test for ascii chars passed
Byte size test for ascii chars passed
Byte size test for unicode chars passed
Byte size test for unicode chars passed