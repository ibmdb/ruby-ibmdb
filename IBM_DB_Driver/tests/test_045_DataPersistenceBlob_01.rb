#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_045_DataPersistenceBlob_01
    assert_expect do
      conn = IBM_DB::connect db,username,password
      fp = File.new("tests/pic1_out.jpg", "wb");
      result = IBM_DB::exec conn, "SELECT picture FROM animal_pics WHERE name = 'Helmut'";
      row = IBM_DB::fetch_array result
      if row
        fp.syswrite row[0]
      else
        print IBM_DB::stmt_errormsg
      end
      fp.close()
      cmp = FileUtils.compare_file( 'tests/pic1_out.jpg', 'tests/pic1.jpg')
      print "Are the files the same: "
      puts cmp

    end
  end

end

__END__
__LUW_EXPECTED__
Are the files the same: true
__ZOS_EXPECTED__
Are the files the same: true
__SYSTEMI_EXPECTED__
Are the files the same: true
__IDS_EXPECTED__
Are the files the same: true
