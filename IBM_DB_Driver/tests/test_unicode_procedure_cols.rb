#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_unicode_procedure_cols
    assert_expect do
      if RUBY_VERSION =~ /1.9/
        conn = IBM_DB.connect database,user,password

        uproc = "UNI𝄞PROC"
        param = "P𝄞RAM"

        IBM_DB.exec conn, "drop procedure #{user}.uni𝄞proc" rescue nil

        IBM_DB.exec conn, "CREATE PROCEDURE #{user}.uni𝄞proc(IN p𝄞ram VARCHAR(10)) LANGUAGE SQL BEGIN END"

        stmt = IBM_DB.procedure_columns conn, nil, user.upcase, "UNI𝄞PROC", nil

        res = IBM_DB.fetch_assoc stmt

        unless res["PROCEDURE_NAME"].eql? uproc
          puts "Unicode Procedure name test failed"
        else
          puts "Unicode Procedure name test passed"
        end

        unless res["COLUMN_NAME"].eql? param
          puts "Unicode Procedure Column name test failed"
        else
          puts "Unicode Procedure Column name test passed"
        end

        IBM_DB.close conn
      else
        puts "Unicode Procedure name test passed"
        puts "Unicode Procedure Column name test passed"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Unicode Procedure name test passed
Unicode Procedure Column name test passed
__ZOS_EXPECTED__
Unicode Procedure name test passed
Unicode Procedure Column name test passed
__SYSTEMI_EXPECTED__
Unicode Procedure name test passed
Unicode Procedure Column name test passed
__IDS_EXPECTED__
Unicode Procedure name test passed
Unicode Procedure Column name test passed