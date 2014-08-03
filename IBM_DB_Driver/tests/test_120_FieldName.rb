# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_120_FieldName
    assert_expect do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if conn
        stmt = IBM_DB::exec conn, "SELECT * FROM animals"
      
        name1 = IBM_DB::field_name stmt, 1
        name2 = IBM_DB::field_name stmt, 2
        name3 = IBM_DB::field_name stmt, 3
        name4 = IBM_DB::field_name stmt, 4
        name6 = IBM_DB::field_name stmt, 8
        name7 = IBM_DB::field_name stmt, 0
        
        if (server.DBMS_NAME[0,3] == 'IDS')
          name5 = IBM_DB::field_name stmt, "id"
          name8 = IBM_DB::field_name stmt, "WEIGHT"
        else
          name5 = IBM_DB::field_name stmt, "ID"
          name8 = IBM_DB::field_name stmt, "weight"
        end

        puts "string(#{name1.length}) #{name1.inspect}"
        puts "string(#{name2.length}) #{name2.inspect}"
        puts "string(#{name3.length}) #{name3.inspect}"
        puts "#{name4}"

        puts "string(#{name5.length}) #{name5.inspect}"
        puts "#{name6}"
        puts "string(#{name7.length}) #{name7.inspect}"
        puts "#{name8}"
      else
        print "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
string(5) "BREED"
string(4) "NAME"
string(6) "WEIGHT"
false
string(2) "ID"
false
string(2) "ID"
false
__ZOS_EXPECTED__
string(5) "BREED"
string(4) "NAME"
string(6) "WEIGHT"
false
string(2) "ID"
false
string(2) "ID"
false
__SYSTEMI_EXPECTED__
string(5) "BREED"
string(4) "NAME"
string(6) "WEIGHT"
false
string(2) "ID"
false
string(2) "ID"
false
__IDS_EXPECTED__
string(5) "breed"
string(4) "name"
string(6) "weight"
false
string(2) "id"
false
string(2) "id"
false
