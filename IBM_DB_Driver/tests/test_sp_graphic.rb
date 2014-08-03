#encoding: UTF-8
#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase
  def test_sp_graphic
    assert_expect do
      exe_input  = 'praveen水  '
      exe_output = 'praveen𝄞 '

      output     = 'garb'
      input      = 'praveen𝄞'

      conn = IBM_DB.connect db,username,password

      IBM_DB.exec conn, "drop procedure #{username}.graphicsp" rescue nil

      IBM_DB.exec conn, "create procedure #{username}.graphicsp(INOUT input graphic(10), OUT output graphic(10)) LANGUAGE SQL SPECIFIC graphicsp BEGIN SET output = input; SET input = 'praveen水' ; END"

      stmt = IBM_DB.prepare conn, "call #{username}.graphicsp(?,?)"

      IBM_DB.bind_param stmt, 1, "input", IBM_DB::SQL_PARAM_INPUT_OUTPUT
      IBM_DB.bind_param stmt, 2, "output", IBM_DB::SQL_PARAM_OUTPUT
      IBM_DB.execute stmt

      if( output == exe_output && input == exe_input)
        puts "Graphic SP test successful"
      else
        puts "Graphic SP test failed"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Graphic SP test successful
__ZOS_EXPECTED__
Graphic SP test successful
__SYSTEMI_EXPECTED__
Graphic SP test successful