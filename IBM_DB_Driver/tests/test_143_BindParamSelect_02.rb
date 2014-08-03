# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_143_BindParamSelect_02
    assert_expect do
      conn = IBM_DB.connect database, user, password
      
      IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

      insert1 = "INSERT INTO animals (id, breed, name, weight)
        VALUES (NULL, 'ghost', NULL, ?)"
      select = 'SELECT id, breed, name, weight FROM animals WHERE weight IS NULL'
      
      if conn
        stmt = IBM_DB.prepare conn, insert1
      
        animal = nil
        IBM_DB.bind_param stmt, 1, "animal"
      
        if IBM_DB::execute(stmt)
          stmt = IBM_DB.exec conn, select
          while (row = IBM_DB.fetch_array(stmt))
            row.each do |child|
              if child.nil?
                puts "nil"
              else
                puts child
              end
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
nil
ghost
nil
nil
__ZOS_EXPECTED__
nil
ghost
nil
nil
__SYSTEMI_EXPECTED__
nil
ghost
nil
nil
__IDS_EXPECTED__
nil
ghost
nil
nil
