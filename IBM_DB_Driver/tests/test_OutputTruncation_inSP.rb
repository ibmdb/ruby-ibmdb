# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_OutputTruncation_inSP
    assert_expect do
      conn = IBM_DB::connect db,username,password
      drop = "DROP PROCEDURE username.SPROC"
      IBM_DB::exec(conn,drop)
      sql = "create procedure username.SPROC(INOUT input varchar(100),OUT output varchar(100))LANGUAGE SQL SPECIFIC SPROC BEGIN SET output = input ; SET input = 'hello world';END"
      IBM_DB::exec(conn,sql)  
      input = "Testing for consistency"
      output = "awaiting output"
      sql = "call username.SPROC(?,?)"
      stmt = IBM_DB::prepare(conn,sql)
      IBM_DB::bind_param(stmt,1,"input",IBM_DB::SQL_PARAM_INPUT_OUTPUT)
      IBM_DB::bind_param(stmt,2,"output",IBM_DB::SQL_PARAM_OUTPUT)
      IBM_DB::execute(stmt)
      print "value of input is #{input}\nvalue of output is #{output}\n"
      drop = "DROP PROCEDURE username.IPROC"
      IBM_DB::exec(conn,drop)
      sql = "create procedure username.IPROC(IN input INTEGER,OUT output INTEGER) LANGUAGE SQL SPECIFIC IPROC BEGIN SET output = input+10;END"
      IBM_DB::exec(conn,sql)  
      iinput = 10
      ioutput = 2
      sql = "call username.IPROC(?,?)"
      stmt = IBM_DB::prepare(conn,sql)
      IBM_DB::bind_param(stmt,1,"iinput",IBM_DB::SQL_PARAM_INPUT)
      IBM_DB::bind_param(stmt,2,"ioutput",IBM_DB::SQL_PARAM_OUTPUT)
      IBM_DB::execute(stmt)
      print "value of ioutput is #{ioutput}"
    end
  end
end   

__END__
__LUW_EXPECTED__
value of input is hello world
value of output is Testing for consistency
value of ioutput is 20
__ZOS_EXPECTED__
value of input is hello world
value of output is Testing for consistency
value of ioutput is 20
__SYSTEMI_EXPECTED__
value of input is hello world
value of output is Testing for consistency
value of ioutput is 20
__IDS_EXPECTED__
value of input is hello world
value of output is Testing for consistency
value of ioutput is 20
