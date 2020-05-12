# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_persistenceConn
    assert_expect do
      pconn = IBM_DB.pconnect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')
      IBM_DB.close pconn
      pconn1 = IBM_DB.pconnect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')
      unless pconn.eql?(pconn1)
        puts "Connection persistence is broken"
      else
        puts "Connection persistence succeded"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Connection persistence succeded
__ZOS_EXPECTED__
Connection persistence succeded
__SYSTEMI_EXPECTED__
Connection persistence succeded
__IDS_EXPECTED__
Connection persistence succeded