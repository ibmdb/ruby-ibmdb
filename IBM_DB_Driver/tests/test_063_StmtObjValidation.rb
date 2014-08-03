# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_063_StmtObjValidation
    assert_expect do
      conn = IBM_DB::connect db,user,password
      
      result = IBM_DB::tables conn, nil, "SYSIBM", "", "VIEW"
     
      if result.class == IBM_DB::Statement
        puts "Resource is a DB2 Statement"
      end
      
      IBM_DB::free_result result
    end
  end

end

__END__
__LUW_EXPECTED__
Resource is a DB2 Statement
__ZOS_EXPECTED__
Resource is a DB2 Statement
__SYSTEMI_EXPECTED__
Resource is a DB2 Statement
__IDS_EXPECTED__
Resource is a DB2 Statement
