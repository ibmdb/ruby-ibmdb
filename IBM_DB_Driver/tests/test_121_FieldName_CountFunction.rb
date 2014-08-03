# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_121_FieldName_CountFunction
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        insert = "INSERT INTO animals values (7, 'cat', 'Benji', 5.1)"
        IBM_DB::exec conn, insert
          
        stmt = IBM_DB::exec conn, "SELECT breed, COUNT(breed) AS number FROM animals GROUP BY breed ORDER BY breed"
      
        name1 = IBM_DB::field_name stmt, 0
        name2 = IBM_DB::field_name stmt, 1
        name3 = IBM_DB::field_name stmt, 2
        name4 = IBM_DB::field_name stmt, 3
        
        if (server.DBMS_NAME[0,3] == 'IDS')
          name5 = IBM_DB::field_name stmt, "breed"
          name6 = IBM_DB::field_name stmt, 7
          name7 = IBM_DB::field_name stmt, '"nUMBER"'
          name8 = IBM_DB::field_name stmt, "number"
        else
          name5 = IBM_DB::field_name stmt, "BREED"
          name6 = IBM_DB::field_name stmt, 7
          name7 = IBM_DB::field_name stmt, '"Number"'
          name8 = IBM_DB::field_name stmt, "NUMBER"
        end

        puts "string(#{name1.length}) #{name1.inspect}"
        puts "string(#{name2.length}) #{name2.inspect}"
        puts "#{name3}"
        puts "#{name4}"

        puts "string(#{name5.length}) #{name5.inspect}"
        puts "#{name6}"
        puts "#{name7}"
        puts "string(#{name8.length}) #{name8.inspect}"

        IBM_DB::rollback conn
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
string(5) "BREED"
string(6) "NUMBER"
false
false
string(5) "BREED"
false
false
string(6) "NUMBER"
__ZOS_EXPECTED__
string(5) "BREED"
string(6) "NUMBER"
false
false
string(5) "BREED"
false
false
string(6) "NUMBER"
__SYSTEMI_EXPECTED__
string(5) "BREED"
string(6) "NUMBER"
false
false
string(5) "BREED"
false
false
string(6) "NUMBER"
__IDS_EXPECTED__
string(5) "breed"
string(6) "number"
false
false
string(5) "breed"
false
false
string(6) "number"
