# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_145_BindParamRetrieveNullString
    assert_expect do
      conn = IBM_DB.connect database, user, password

      if conn
        IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

        stmt = IBM_DB.prepare conn, "INSERT INTO animals (id, breed, name) VALUES (?, ?, ?)"

        id = 999
        breed = nil
        name = 'RubyDB2'
        IBM_DB.bind_param stmt, 1, 'id'
        IBM_DB.bind_param stmt, 2, 'breed'
        IBM_DB.bind_param stmt, 3, 'name'

        # After this statement, we expect that the BREED column will contain
        # an SQL NULL value, while the NAME column contains an empty string

        IBM_DB.execute(stmt); 

        # After this statement, we expect that the BREED column will contain
        # an SQL NULL value, while the NAME column contains an empty string.
        # Use the dynamically bound parameters to ensure that the code paths
        # for both IBM_DB::bind_param and IBM_DB::execute treat PHP nils and empty
        # strings the right way.

        IBM_DB::execute(stmt, [1000, nil, 'RubyDB2']); 

        result = IBM_DB::exec conn, "SELECT id, breed, name FROM animals WHERE breed IS NULL"
        while (row = IBM_DB.fetch_array(result))
          row.each do |child|
            if child.nil?
              puts "nil"
            else
              puts child
            end
          end
        end

        IBM_DB.rollback conn
      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
999
nil
RubyDB2         
1000
nil
RubyDB2
__ZOS_EXPECTED__
999
nil
RubyDB2         
1000
nil
RubyDB2
__SYSTEMI_EXPECTED__
999
nil
RubyDB2         
1000
nil
RubyDB2
__IDS_EXPECTED__
999
nil
RubyDB2         
1000
nil
RubyDB2
