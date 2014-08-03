# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_153_FetchAssocMany_03
    assert_expect do
      conn = IBM_DB::connect db,username,password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end
      
      result = IBM_DB::exec conn, "select * from org"
      
      while (row = IBM_DB::fetch_assoc(result))
      printf("%4d ",row['DEPTNUMB'])
      printf("%-14s ",row['DEPTNAME'])
      printf("%4d ",row['MANAGER'])
      printf("%-10s",row['DIVISION'])
      printf("%-13s ",row['LOCATION'])
      
      puts ""
      end
    end
  end

end

__END__
__LUW_EXPECTED__

  10 Head Office     160 Corporate New York      
  15 New England      50 Eastern   Boston        
  20 Mid Atlantic     10 Eastern   Washington    
  38 South Atlantic   30 Eastern   Atlanta       
  42 Great Lakes     100 Midwest   Chicago       
  51 Plains          140 Midwest   Dallas        
  66 Pacific         270 Western   San Francisco 
  84 Mountain        290 Western   Denver
__ZOS_EXPECTED__

  10 Head Office     160 Corporate New York      
  15 New England      50 Eastern   Boston        
  20 Mid Atlantic     10 Eastern   Washington    
  38 South Atlantic   30 Eastern   Atlanta       
  42 Great Lakes     100 Midwest   Chicago       
  51 Plains          140 Midwest   Dallas        
  66 Pacific         270 Western   San Francisco 
  84 Mountain        290 Western   Denver
__SYSTEMI_EXPECTED__

  10 Head Office     160 Corporate New York      
  15 New England      50 Eastern   Boston        
  20 Mid Atlantic     10 Eastern   Washington    
  38 South Atlantic   30 Eastern   Atlanta       
  42 Great Lakes     100 Midwest   Chicago       
  51 Plains          140 Midwest   Dallas        
  66 Pacific         270 Western   San Francisco 
  84 Mountain        290 Western   Denver        
__IDS_EXPECTED__

  10 Head Office     160 Corporate New York      
  15 New England      50 Eastern   Boston        
  20 Mid Atlantic     10 Eastern   Washington    
  38 South Atlantic   30 Eastern   Atlanta       
  42 Great Lakes     100 Midwest   Chicago       
  51 Plains          140 Midwest   Dallas        
  66 Pacific         270 Western   San Francisco 
  84 Mountain        290 Western   Denver        

