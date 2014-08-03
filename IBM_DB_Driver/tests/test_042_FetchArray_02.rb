# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_042_FetchArray_02
    assert_expect do
      conn = IBM_DB::connect db,username,password
      
      if ({}['EMPNO'] != nil)
        result = IBM_DB::exec conn, "select photo_format, picture, length(picture) from emp_photo where photo_format='jpg' and empno='" + {}['EMPNO'] + "'"
        row = IBM_DB::fetch_array(result);             
        if row
          # We'll be outputting a         
          header('Content-type: image/' + row[0])
          header('Content-Length: ' + row[2])
          print "#{row[1]}";            
        else
          print "#{IBM_DB::error}";            
        end
        next
      else
        result = IBM_DB::exec(conn, "select EMPNO, PHOTO_FORMAT from emp_photo where photo_format='jpg'");    
        while (row = IBM_DB::fetch_array(result))
          printf("<a href='test_042.php?EMPNO=%s' target=_blank>%s (%s)</a><br>",row[0], row[0], row[1])
          puts ""
        end
      end
    end
  end

end

__END__
__LUW_EXPECTED__
<a href='test_042.php?EMPNO=000130' target=_blank>000130 (jpg)</a><br>
<a href='test_042.php?EMPNO=000140' target=_blank>000140 (jpg)</a><br>
<a href='test_042.php?EMPNO=000150' target=_blank>000150 (jpg)</a><br>
<a href='test_042.php?EMPNO=000190' target=_blank>000190 (jpg)</a><br>
__ZOS_EXPECTED__
<a href='test_042.php?EMPNO=000130' target=_blank>000130 (jpg)</a><br>
<a href='test_042.php?EMPNO=000140' target=_blank>000140 (jpg)</a><br>
<a href='test_042.php?EMPNO=000150' target=_blank>000150 (jpg)</a><br>
<a href='test_042.php?EMPNO=000190' target=_blank>000190 (jpg)</a><br>
__SYSTEMI_EXPECTED__
<a href='test_042.php?EMPNO=000130' target=_blank>000130 (jpg)</a><br>
<a href='test_042.php?EMPNO=000140' target=_blank>000140 (jpg)</a><br>
<a href='test_042.php?EMPNO=000150' target=_blank>000150 (jpg)</a><br>
<a href='test_042.php?EMPNO=000190' target=_blank>000190 (jpg)</a><br>
__IDS_EXPECTED__
<a href='test_042.php?EMPNO=000130' target=_blank>000130 (jpg)</a><br>
<a href='test_042.php?EMPNO=000140' target=_blank>000140 (jpg)</a><br>
<a href='test_042.php?EMPNO=000150' target=_blank>000150 (jpg)</a><br>
<a href='test_042.php?EMPNO=000190' target=_blank>000190 (jpg)</a><br>

