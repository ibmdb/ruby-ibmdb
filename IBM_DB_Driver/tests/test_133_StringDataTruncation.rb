# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_133_StringDataTruncation
    assert_expect do
      sql =  "INSERT INTO animals (id, breed, name, weight) VALUES (?, ?, ?, ?)"
      conn = IBM_DB.connect database, user, password

      if !conn
        print "Connection failed.\n"; return 0
      end

      IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

      puts "Starting test ..."

      begin
        stmt = IBM_DB.prepare conn, sql
        res = IBM_DB.execute stmt, [128, 'hacker of human and technological nature', 'Wez the ruler of all things PECL', 88.3]
        if( !res )
          puts res
          puts "SQLSTATE: #{IBM_DB.getErrorstate(stmt, IBM_DB::DB_STMT)}"
          puts "Message: #{IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)}"
        end

        stmt = IBM_DB.prepare conn, "SELECT breed, name FROM animals WHERE id = ?"
        res = IBM_DB.execute stmt, [128]
        if res
          row = IBM_DB.fetch_assoc stmt
          if row
            row.each { |r| print r + "\n" }
            IBM_DB.rollback conn
            print "Done"
          else
            puts "Expected behaviour: No row found for fetch"
          end
        else
          puts res
          puts "SQLSTATE: #{IBM_DB.getErrorstate(stmt, IBM_DB::DB_STMT )}"
          puts "Message: #{IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )}"
        end
      rescue StandardError => err
        raise "An unexpected error occurred #{err}"
      ensure
        IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_ON
      end
    end
  end

end

__END__
__LUW_EXPECTED__
Starting test ...
false
SQLSTATE: 22001
Message: [IBM][CLI Driver] CLI0109E  String data right truncation. SQLSTATE=22001 SQLCODE=-99999
Expected behaviour: No row found for fetch
__ZOS_EXPECTED__
Starting test ...
false
SQLSTATE: 22001
Message: [IBM][CLI Driver] CLI0109E  String data right truncation. SQLSTATE=22001 SQLCODE=-99999
Expected behaviour: No row found for fetch
__SYSTEMI_EXPECTED__
Starting test ...
false
SQLSTATE: 22001
Message: [IBM][CLI Driver] CLI0109E  String data right truncation. SQLSTATE=22001 SQLCODE=-99999
Expected behaviour: No row found for fetch
__IDS_EXPECTED__
Starting test ...
false
SQLSTATE: 22001
Message: [IBM][CLI Driver][IDS%s] Value exceeds string column length.
Expected behaviour: No row found for fetch
