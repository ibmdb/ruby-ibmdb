# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_066_FetchObject
    assert_expectf do
      conn = IBM_DB::connect database, user, password
      server = IBM_DB::server_info( conn )

      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::tables conn, nil, user.downcase, 'animals'
      else
        result = IBM_DB::tables conn, nil, user.upcase, 'ANIMALS'
      end
      
      while (row = IBM_DB::fetch_object(result))
        if (server.DBMS_NAME[0,3] == 'IDS')
          puts "Schema:  #{row.table_schem}"
          puts "Name:    #{row.table_name}"
          puts "Type:    #{row.table_type}"
          print "Remarks: #{row.remarks}\n\n"
        else
          puts "Schema:  #{row.TABLE_SCHEM}"
          puts "Name:    #{row.TABLE_NAME}"
          puts "Type:    #{row.TABLE_TYPE}"
          print "Remarks: #{row.REMARKS}\n\n"
        end
      end

      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::tables conn, nil, user.downcase, 'animal_pics'
      else
        result = IBM_DB::tables conn, nil, user.upcase, 'ANIMAL_PICS'
      end
      
      while (row = IBM_DB::fetch_object(result))
        if (server.DBMS_NAME[0,3] == 'IDS')
          puts "Schema:  #{row.table_schem}"
          puts "Name:    #{row.table_name}"
          puts "Type:    #{row.table_type}"
          print "Remarks: #{row.remarks}\n\n"
        else
          puts "Schema:  #{row.TABLE_SCHEM}"
          puts "Name:    #{row.TABLE_NAME}"
          puts "Type:    #{row.TABLE_TYPE}"
          print "Remarks: #{row.REMARKS}\n\n"
        end
      end

      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::tables conn, nil, user.downcase, 'anime_cat'
      else
        result = IBM_DB::tables conn, nil, user.upcase, 'ANIME_CAT'
      end
      
      while (row = IBM_DB::fetch_object(result))
        if (server.DBMS_NAME[0,3] == 'IDS')
          puts "Schema:  #{row.table_schem}"
          puts "Name:    #{row.table_name}"
          puts "Type:    #{row.table_type}"
          print "Remarks: #{row.remarks}\n\n"
        else
          puts "Schema:  #{row.TABLE_SCHEM}"
          puts "Name:    #{row.TABLE_NAME}"
          puts "Type:    #{row.TABLE_TYPE}"
          print "Remarks: #{row.REMARKS}\n\n"
        end
      end
      
      IBM_DB::free_result result
      IBM_DB::close conn
    end
  end

end

__END__
__LUW_EXPECTED__
Schema:  %s
Name:    ANIMALS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIMAL_PICS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIME_CAT
Type:    VIEW
Remarks:
__ZOS_EXPECTED__
Schema:  %s
Name:    ANIMALS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIMAL_PICS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIME_CAT
Type:    VIEW
Remarks:
__SYSTEMI_EXPECTED__
Schema:  %s
Name:    ANIMALS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIMAL_PICS
Type:    TABLE
Remarks: 

Schema:  %s
Name:    ANIME_CAT
Type:    VIEW
Remarks:
__IDS_EXPECTED__
Schema:  %s
Name:    animals
Type:    TABLE
Remarks: 

Schema:  %s
Name:    animal_pics
Type:    TABLE
Remarks: 

Schema:  %s
Name:    anime_cat
Type:    VIEW
Remarks:
