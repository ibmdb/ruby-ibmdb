# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_080_ConnWrngdbalias
    assert_expectf do
      begin
        conn = IBM_DB.connect("x", user, password)
        if conn
          puts "??? No way."
        end
      rescue
        puts "Connection Failed"
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Connection Failed
__ZOS_EXPECTED__
Connection Failed
__SYSTEMI_EXPECTED__
Connection Failed
__IDS_EXPECTED__
Connection Failed
