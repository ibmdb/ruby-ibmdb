#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_unicode_columns
    assert_expect do
      if RUBY_VERSION =~ /1.9/
        conn = IBM_DB.connect database,user,password

        utab = "UNI𝄞TAB"
        col  = "C𝄞L1"
        col2 = "COL2"

        IBM_DB.exec conn, "drop table #{utab}" rescue nil
        stmt = IBM_DB.exec conn, "create table #{utab}(#{col} varchar(5), #{col2} double)"

        if stmt
          col_stmt = IBM_DB.columns conn, nil, user.upcase, utab, nil
          if col_stmt
            res = IBM_DB.fetch_array(col_stmt)
            unless (res[3].eql? col)
              puts "Unicode column name retrieved is incorrect"
            else
              puts "Unicode column name retrieved correctly"
            end
	
            res = IBM_DB.fetch_array(col_stmt)
            unless (res[3].eql? col2)
              puts "Ascii column name retrieved is incorrect"
            else
              puts "Ascii column name retrieved correctly"
            end
          else
            puts "column metadata retrieve failed"
          end
        else
          puts "Create table failed"
        end

        IBM_DB.close conn
      else
        puts "Unicode column name retrieved correctly"
        puts "Ascii column name retrieved correctly"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Unicode column name retrieved correctly
Ascii column name retrieved correctly
__ZOS_EXPECTED__
Unicode column name retrieved correctly
Ascii column name retrieved correctly
__SYSTEMI_EXPECTED__
Unicode column name retrieved correctly
Ascii column name retrieved correctly
__IDS_EXPECTED__
Unicode column name retrieved correctly
Ascii column name retrieved correctly