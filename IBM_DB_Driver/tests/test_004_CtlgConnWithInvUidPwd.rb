# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_004_CtlgConnWithInvUidPwd
    assert_expect do
      begin
        conn = IBM_DB.connect "sample", "not_a_user", "inv_pass"
        puts "connect succeeded? Test failed"
      rescue StandardError => connect_err
        puts "connect failed, test succeeded"
      end
    end
  end

end

__END__
__LUW_EXPECTED__
connect failed, test succeeded
__ZOS_EXPECTED__
connect failed, test succeeded
__SYSTEMI_EXPECTED__
connect failed, test succeeded
__IDS_EXPECTED__
connect failed, test succeeded
