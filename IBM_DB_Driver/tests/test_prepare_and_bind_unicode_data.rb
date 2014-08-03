#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2010
#

class TestIbmDb < Test::Unit::TestCase

  def test_prepare_and_bind_unicode_data
    assert_expect do
      if RUBY_VERSION =~ /1.9/
        conn = IBM_DB.connect(database,username,password, nil, IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF)
        table_name =  "test_tab𝄞"

        if conn
          IBM_DB.exec conn,"drop table  #{table_name}" rescue nil
          IBM_DB.exec conn,"create table  #{table_name} (id integer, name varchar(14))"
          IBM_DB.exec conn,"insert into #{table_name} values (1, 'praveen文𝄞')"
  
          stmt = IBM_DB.prepare conn, "select * from #{table_name} where name = ?", {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_STATIC}
  
          some_val = "praveen文𝄞"

          IBM_DB.bind_param stmt, 1, "some_val"

          if(IBM_DB.execute stmt)
            if( res = IBM_DB.fetch_assoc stmt)
              if res["ID"] ==  1 && res["NAME"].eql?(some_val)
                puts "Unicode Data prepare test succeeded"
              else
                puts "Unicode Data prepare test Failed"
              end
            else
              puts "No data retrieved"
            end
          else
            puts "Statement execution failed"
          end
        else
          puts "Connection failed"
        end
      else
        puts "Unicode Data prepare test succeeded"
      end
    end
  end
end

__END__
__LUW_EXPECTED__
Unicode Data prepare test succeeded
__ZOS_EXPECTED__
Unicode Data prepare test succeeded
__SYSTEMI_EXPECTED__
Unicode Data prepare test succeeded
__IDS_EXPECTED__
Unicode Data prepare test succeeded