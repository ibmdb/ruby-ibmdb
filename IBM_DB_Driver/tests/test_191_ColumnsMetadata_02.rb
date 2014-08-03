# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#
# NOTE: IDS requires that you pass the schema name (cannot pass nil)

class TestIbmDb < Test::Unit::TestCase

  def test_191_ColumnsMetadata_02
    assert_expectf do
      conn = IBM_DB::connect db,username,password
      server = IBM_DB::server_info( conn )

      if conn
        if (server.DBMS_NAME[0,3] == 'IDS')
          result = IBM_DB::columns(conn,nil,user,"emp_photo");    
        else
          result = IBM_DB::columns(conn,nil,nil,"EMP_PHOTO");    
        end

        i = 0
        while (row = IBM_DB::fetch_both(result))
          if (server.DBMS_NAME[0,3] == 'IDS')
            if row['column_name'] != 'emp_rowid' && i < 3
              printf("%s,%s,%s,%s\n", row['table_schem'], 
              row['table_name'], row['column_name'], row['is_nullable'])
            end
          else 
            if row['COLUMN_NAME'] != 'EMP_ROWID' && i < 3
              printf("%s,%s,%s,%s\n", row['TABLE_SCHEM'], 
              row['TABLE_NAME'], row['COLUMN_NAME'], row['IS_NULLABLE'])
            end
          end
         i = i + 1
        end
        print "done!"
      else
        print "no connection: #{IBM_DB::conn_errormsg}";    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
%s,EMP_PHOTO,EMPNO,NO
%s,EMP_PHOTO,PHOTO_FORMAT,NO
%s,EMP_PHOTO,PICTURE,YES
done!
__ZOS_EXPECTED__
%s,EMP_PHOTO,EMPNO,NO
%s,EMP_PHOTO,PHOTO_FORMAT,NO
%s,EMP_PHOTO,PICTURE,YES
done!
__SYSTEMI_EXPECTED__
%s,EMP_PHOTO,EMPNO,NO
%s,EMP_PHOTO,PHOTO_FORMAT,NO
%s,EMP_PHOTO,PICTURE,YES
done!
__IDS_EXPECTED__
%s,emp_photo,empno,NO
%s,emp_photo,photo_format,NO
%s,emp_photo,picture,YES
done!
