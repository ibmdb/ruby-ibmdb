# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_200_MultipleResultSets_01
    assert_expect do
      conn = IBM_DB::connect database, user, password
      serverinfo = IBM_DB::server_info( conn )
      server = serverinfo.DBMS_NAME[0,3]
      if (server == 'IDS')
         procedure = <<-IDS
          CREATE FUNCTION multiResults()
	     RETURNING CHAR(16), INT;
	            
	     DEFINE p_name CHAR(16);
	     DEFINE p_id INT;
	           
	     FOREACH c1 FOR
	     	SELECT name, id
	      	INTO p_name, p_id
	       	FROM animals
	       	ORDER BY name
	      	RETURN p_name, p_id WITH RESUME;
	     END FOREACH;
	            
         END FUNCTION;
         IDS
      else
         procedure = <<-HERE
          CREATE PROCEDURE multiResults ()
          RESULT SETS 3
          LANGUAGE SQL
          BEGIN
           DECLARE c1 CURSOR WITH RETURN FOR
            SELECT name, id
            FROM animals
            ORDER BY name;
      
           DECLARE c2 CURSOR WITH RETURN FOR
            SELECT name, id
            FROM animals
            WHERE id < 4
            ORDER BY name DESC;
      
           DECLARE c3 CURSOR WITH RETURN FOR
            SELECT name, id
            FROM animals
            WHERE weight < 5.0
            ORDER BY name;
      
           OPEN c1;
           OPEN c2;
           OPEN c3;
          END
         HERE
      end
      
      if conn
       IBM_DB::exec(conn, 'DROP PROCEDURE multiResults()') rescue nil
       IBM_DB::exec conn, procedure
       stmt = IBM_DB::exec conn, 'CALL multiResults()'
      
       puts "Fetching first result set"
       while (row = IBM_DB::fetch_array(stmt))
        row.each { |child| puts child }
       end
      
       if (server == 'IDS') 
        puts "Fetching second result set (should fail -- IDS does not support multiple result sets)"
       else
        puts "Fetching second result set"
       end
       res = IBM_DB::next_result stmt
       if res
        while (row = IBM_DB::fetch_array(res))
         row.each { |child| puts child }
        end
       end
      
       if (server == 'IDS') 
        puts "Fetching third result set (should fail -- IDS does not support multiple result sets)"
       else
        puts "Fetching third result set"
       end
       res2 = IBM_DB::next_result stmt
       if res2
        while (row = IBM_DB::fetch_array(res2))
         row.each { |child| puts child }
        end
       end
      
       puts "Fetching fourth result set (should fail)"
       res3 = IBM_DB::next_result stmt
       if res3
        while (row = IBM_DB::fetch_array(res3))
         row.each { |child| puts child }
        end
       end
      
       IBM_DB::close conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Fetching first result set
Bubbles         
3
Gizmo           
4
Peaches         
1
Pook            
0
Rickety Ride    
5
Smarty          
2
Sweater         
6
Fetching second result set
Smarty          
2
Pook            
0
Peaches         
1
Bubbles         
3
Fetching third result set
Bubbles         
3
Gizmo           
4
Pook            
0
Fetching fourth result set (should fail)
__ZOS_EXPECTED__
Fetching first result set
Bubbles         
3
Gizmo           
4
Peaches         
1
Pook            
0
Rickety Ride    
5
Smarty          
2
Sweater         
6
Fetching second result set
Smarty          
2
Pook            
0
Peaches         
1
Bubbles         
3
Fetching third result set
Bubbles         
3
Gizmo           
4
Pook            
0
Fetching fourth result set (should fail)
__SYSTEMI_EXPECTED__
Fetching first result set
Bubbles         
3
Gizmo           
4
Peaches         
1
Pook            
0
Rickety Ride    
5
Smarty          
2
Sweater         
6
Fetching second result set
Smarty          
2
Pook            
0
Peaches         
1
Bubbles         
3
Fetching third result set
Bubbles         
3
Gizmo           
4
Pook            
0
Fetching fourth result set (should fail)
__IDS_EXPECTED__
Fetching first result set
Bubbles         
3
Gizmo           
4
Peaches         
1
Pook            
0
Rickety Ride    
5
Smarty          
2
Sweater         
6
Fetching second result set (should fail -- IDS does not support multiple result sets)
Fetching third result set (should fail -- IDS does not support multiple result sets)
Fetching fourth result set (should fail)
