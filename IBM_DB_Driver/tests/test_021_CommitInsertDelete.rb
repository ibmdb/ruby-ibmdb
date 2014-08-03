# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_021_CommitInsertDelete
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows
        
        IBM_DB::autocommit conn, 0
        ac = IBM_DB::autocommit conn
        if ac != 0
          puts "Cannot set IBM_DB::AUTOCOMMIT_OFF\nCannot run test"
          next
        end
        
        IBM_DB::exec conn, "DELETE FROM animals"
        
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows
        
        IBM_DB::commit conn
        
        stmt = IBM_DB::exec conn, "SELECT count(*) FROM animals"
        res = IBM_DB::fetch_array stmt
        rows = res[0]
        puts rows

        # Populate the animal table
        animals = [
          [0, 'cat',        'Pook',         3.2],
          [1, 'dog',        'Peaches',      12.3],
          [2, 'horse',      'Smarty',       350.0],
          [3, 'gold fish',  'Bubbles',      0.1],
          [4, 'budgerigar', 'Gizmo',        0.2],
          [5, 'goat',       'Rickety Ride', 9.7],
          [6, 'llama',      'Sweater',      150]
        ]
        insert = 'INSERT INTO animals (id, breed, name, weight) VALUES (?, ?, ?, ?)'
        stmt = IBM_DB::prepare conn, insert
        if stmt
          for animal in animals
            result = IBM_DB::execute stmt, animal
          end
        end
        IBM_DB::commit conn
        IBM_DB::close conn

      else
        puts "Connection failed."
      end
    end
  end

end

__END__
__LUW_EXPECTED__
7
0
0
__ZOS_EXPECTED__
7
0
0
__SYSTEMI_EXPECTED__
7
0
0
__IDS_EXPECTED__
7
0
0
