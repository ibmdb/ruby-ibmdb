# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_Bigint
    assert_expect do
      conn = IBM_DB.connect db,username,password
      drop_table_sql = 'drop table table0'
      stmt = IBM_DB.exec(conn,drop_table_sql)  rescue nil

      #Create table table0 with 2 columns of type bigint
      create_table_sql = 'create table table0( id1 bigint , id2 bigint) '
      stmt = IBM_DB.exec(conn,create_table_sql)
  
      #Insert into table table0 big values	  
      sql = 'insert into table0 values(?,?)'

      param1 = 922337203685477580
      param2 = 922337203685477581
      param3 = 922337203685477589

      #Prepare statement
      prepared_stmt = IBM_DB.prepare conn,sql
      IBM_DB.bind_param(prepared_stmt,1,'param1') #Bind Parameter 1
      IBM_DB.bind_param(prepared_stmt,2,'param2') #Bind parameter 2

      #Execute statement
      IBM_DB.execute(prepared_stmt)  
      #Retreive the inserted values
      result = IBM_DB.exec conn,'select * from table0'
      if result
        while(row = IBM_DB.fetch_array result)
          row.each {|value| print "#{value} |"}
          print "\n"
        end    
      end

      drop_proc_sql = 'drop procedure update_bigint_col'
      stmt = IBM_DB.exec(conn,drop_proc_sql)  rescue nil

      #Create procedure with 2 IN parameters of type bigint
      create_proc_sql = "CREATE PROCEDURE update_bigint_col (IN param1 bigint, IN param2 bigint)\
                          BEGIN UPDATE table0 SET (id1) = (param1) WHERE id2 = param2; \
                          END"
      stmt = IBM_DB.exec(conn,create_proc_sql)

      call_sql = 'call update_bigint_col(?,?)'

      #Prepare statement
      prepared_stmt = IBM_DB.prepare conn,call_sql
      IBM_DB.bind_param(prepared_stmt,1,'param3') #Bind Parameter 1
      IBM_DB.bind_param(prepared_stmt,2,'param2') #Bind Parameter 2

      #Execute statement
      IBM_DB.execute(prepared_stmt)

      #Retreive the values updated through the Stored Proc
      result = IBM_DB.exec conn,'select * from table0'
      if result
        while(row = IBM_DB.fetch_array result)
          row.each {|value| print "#{value} |"}
          print "\n"
        end
      end
    end
  end
end   

__END__
__LUW_EXPECTED__
922337203685477580 |922337203685477581 |
922337203685477589 |922337203685477581 |
__ZOS_EXPECTED__
922337203685477580 |922337203685477581 |
922337203685477589 |922337203685477581 |
__SYSTEMI_EXPECTED__
922337203685477580 |922337203685477581 |
922337203685477589 |922337203685477581 |
