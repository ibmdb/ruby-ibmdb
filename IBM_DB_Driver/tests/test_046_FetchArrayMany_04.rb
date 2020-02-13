# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_046_FetchArrayMany_04
    assert_expect do
      conn = IBM_DB.connect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')
      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        result = IBM_DB::exec(conn, "SELECT empno, photo_format FROM emp_photo");    
      else
        result = IBM_DB::exec(conn, "SELECT empno, photo_format FROM emp_photo");    
      end
      
      while (row = IBM_DB::fetch_array(result))
        if row[1] != 'xwd'
          printf("<a href='test_046.php?EMPNO=%s&FORMAT=%s' target=_blank>%s - %s </a><br>",row[0], row[1], row[0], row[1])
          puts ""
        end
      end
    end
  end

end

__END__
__LUW_EXPECTED__
<a href='test_046.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg </a><br>
<a href='test_046.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png </a><br>
__ZOS_EXPECTED__
<a href='test_046.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg </a><br>
<a href='test_046.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png </a><br>
__SYSTEMI_EXPECTED__
<a href='test_046.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg </a><br>
<a href='test_046.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png </a><br>
__IDS_EXPECTED__
<a href='test_046.php?EMPNO=000130&FORMAT=jpg' target=_blank>000130 - jpg </a><br>
<a href='test_046.php?EMPNO=000130&FORMAT=png' target=_blank>000130 - png </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=jpg' target=_blank>000140 - jpg </a><br>
<a href='test_046.php?EMPNO=000140&FORMAT=png' target=_blank>000140 - png </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=jpg' target=_blank>000150 - jpg </a><br>
<a href='test_046.php?EMPNO=000150&FORMAT=png' target=_blank>000150 - png </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=jpg' target=_blank>000190 - jpg </a><br>
<a href='test_046.php?EMPNO=000190&FORMAT=png' target=_blank>000190 - png </a><br>
