# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_047_FetchArrayMany_05
    assert_expect do
      conn = IBM_DB::connect db,username,password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::exec(conn, "SELECT empno, photo_format, photo_format from emp_photo");    
      else
        result = IBM_DB::exec(conn, "SELECT empno, photo_format, length(PICTURE) from emp_photo");    
      end
      
      while (row = IBM_DB::fetch_array(result))
        if row[1] == 'gif'
          printf("<img src='test_047.php?EMPNO=%s&FORMAT=%s'><br>\n",row[0],row[1])
        end
        if row[1] != 'xwd'
          printf("<a href='test_047.php?EMPNO=%s&FORMAT=%s' target=_blank>%s - %s - %s bytes</a>\n", row[0], row[1], row[0], row[1], row[2]);    
          print "<br>"
        end    
      end
    end
  end

end

__END__
__LUW_EXPECTED__
<a href='test_047.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png - 9 bytes</a>
<br>
__ZOS_EXPECTED__
<a href='test_047.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png - 9 bytes</a>
<br>
__SYSTEMI_EXPECTED__
<a href='test_047.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png - 9 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg - 8 bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png - 9 bytes</a>
<br>
__IDS_EXPECTED__
<a href='test_047.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg - jpg bytes</a>
<br><a href='test_047.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png - png bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg - jpg bytes</a>
<br><a href='test_047.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png - png bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg - jpg bytes</a>
<br><a href='test_047.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png - png bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg - jpg bytes</a>
<br><a href='test_047.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png - png bytes</a>
<br>
