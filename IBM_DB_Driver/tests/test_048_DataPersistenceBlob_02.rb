#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_048_DataPersistenceBlob_02
    assert_expect do
      conn = IBM_DB::connect database, username, password
      if !conn
       print "Could not make a connection."; return 0
      end
      fp = File.new("tests/spook_out.png", "wb");
      result = IBM_DB::exec(conn, "SELECT picture, LENGTH(picture)
        FROM animal_pics
        WHERE name = 'Spook'")
      if !result
       print "Could not execute SELECT statement."; return 0
      end
      row = IBM_DB::fetch_array result
      if row
        fp.syswrite row[0]
      else
        print IBM_DB::stmt_errormsg
      end
      fp.close()
      cmp = FileUtils.compare_file('tests/spook_out.png', 'tests/spook.png')
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
