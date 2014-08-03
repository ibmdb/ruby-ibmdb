# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_201_MultipleResultSets_02
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      serverinfo = IBM_DB::server_info( conn )
      server = serverinfo.DBMS_NAME[0,3]
      if (server == 'IDS')
	procedure = <<-IDS
          CREATE FUNCTION multiResults ()
             RETURNING CHAR(16), INT, VARCHAR(32), NUMERIC(7,2);
             
             DEFINE p_name CHAR(16);
             DEFINE p_id INT;
             DEFINE p_breed VARCHAR(32);
             DEFINE p_weight NUMERIC(7,2);
             
             FOREACH c1 FOR
            	SELECT name, id, breed, weight
            	INTO p_name, p_id, p_breed, p_weight
            	FROM animals
            	ORDER BY name DESC
            	RETURN p_name, p_id, p_breed, p_weight WITH RESUME;
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
            SELECT name, id, breed, weight
            FROM animals
            ORDER BY name DESC;
      
           DECLARE c3 CURSOR WITH RETURN FOR
            SELECT name
            FROM animals
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
Sweater         
6
llama
0.15E3
Smarty          
2
horse
0.35E3
Rickety Ride    
5
goat
0.97E1
Pook            
0
cat
0.32E1
Peaches         
1
dog
0.123E2
Gizmo           
4
budgerigar
0.2E0
Bubbles         
3
gold fish
0.1E0
Fetching third result set
Bubbles         
Gizmo           
Peaches         
Pook            
Rickety Ride    
Smarty          
Sweater
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
Sweater         
6
llama
0.15E3
Smarty          
2
horse
0.35E3
Rickety Ride    
5
goat
0.97E1
Pook            
0
cat
0.32E1
Peaches         
1
dog
0.123E2
Gizmo           
4
budgerigar
0.2E0
Bubbles         
3
gold fish
0.1E0
Fetching third result set
Bubbles         
Gizmo           
Peaches         
Pook            
Rickety Ride    
Smarty          
Sweater
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
Sweater         
6
llama
0.15E3
Smarty          
2
horse
0.35E3
Rickety Ride    
5
goat
0.97E1
Pook            
0
cat
0.32E1
Peaches         
1
dog
0.123E2
Gizmo           
4
budgerigar
0.2E0
Bubbles         
3
gold fish
0.1E0
Fetching third result set
Bubbles         
Gizmo           
Peaches         
Pook            
Rickety Ride    
Smarty          
Sweater
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
Fetching second result set
Sweater         
6
llama
0.15E3
Smarty          
2
horse
0.35E3
Rickety Ride    
5
goat
0.97E1
Pook            
0
cat
0.32E1
Peaches         
1
dog
0.123E2
Gizmo           
4
budgerigar
0.2E0
Bubbles         
3
gold fish
0.1E0
Fetching third result set
Bubbles         
Gizmo           
Peaches         
Pook            
Rickety Ride    
Smarty          
Sweater
