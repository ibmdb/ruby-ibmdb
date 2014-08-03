#encoding: UTF-8

#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2011
#

#This test case will insert a unique row into the table (primary key column id). and then depending on the case (Autocommit ON/OFF)
#will try to insert the same row (with same id value) ane expect it to fail or pass accordingly.
#One cannot use a select statement to retrieve the row with respective id and verify that txn was successful
#because no rows does not gaurantee that the txn was rolled back.

class TestIbmDb < Test::Unit::TestCase
  def prepareDB()
      conn = IBM_DB.connect db,username,password

      IBM_DB.exec conn, "drop table dealloctab" rescue nil
      IBM_DB.exec conn, "create table dealloctab(id integer not null primary key, name varchar(20))"
  end

  def cleanDB()
    conn = IBM_DB.connect db,username,password
     IBM_DB.exec conn, "drop table dealloctab"
  end

  #Check for transaction with Autocommit ON. Autocommit setting triggered from IBM_DB._autocommit.
  def case1()
    conn = IBM_DB.connect db,username,password
    IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_ON

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (1, 'case1')"
    if( !stmt )
      puts "case 1 insertion failed"
      puts IBM_DB.getErrormsg conn, IBM_DB::DB_CONN
    end   
  end

  def verifyCase1()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (1, 'case1')"
    if( !stmt )
      puts "Test Case 1 passed" #Insertion should fail as transaction was committed
    end
  end

  #Check for transaction with Autocommit OFF. Autocommit setting triggered from IBM_DB._autocommit
  def case2()
    conn = IBM_DB.connect db,username,password
    IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (2, 'case2')"
    if( !stmt )
      puts "case 2 insertion failed"
    end
  end

  def verifyCase2()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (2, 'case2')"
    if( stmt )
      puts "Test Case 2 passed" #Insertion should go through successfully as transaction was rolled back
    end
  end

  #Check for transaction with Autocommit ON. Autocommit setting triggered from IBM_DB.set_option.
  def case3()
    conn = IBM_DB.connect db,username,password
    IBM_DB.set_option conn, {IBM_DB::SQL_ATTR_AUTOCOMMIT => IBM_DB::SQL_AUTOCOMMIT_ON}, 1
    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (3, 'case3')"
    if( !stmt )
      puts "case 3 insertion failed"
    end
  end

  def verifyCase3()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (3, 'case3')"
    if( !stmt )
      puts "Test Case 3 passed" #Insertion should fail as previous transaction was successful
    end
  end

  #Check for transaction with Autocommit OFF. Autocommit setting triggered from IBM_DB.set_option.
  def case4()
    conn = IBM_DB.connect db,username,password
    IBM_DB.set_option conn, {IBM_DB::SQL_ATTR_AUTOCOMMIT => IBM_DB::SQL_AUTOCOMMIT_OFF}, 1
    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (4, 'case4')"
    if( !stmt )
      puts "case 4 insertion failed"
    end
  end

  def verifyCase4()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (4, 'case4')"
    if( stmt )
      puts "Test Case 4 passed" #Insertion should go through successfully as transaction was rolled back
    end
  end

  # Check for clean transaction with Autocommit OFF and autocommit turned ON after transaction complete. Autocommit setting triggered from IBM_DB.set_option
  def case5()
    conn = IBM_DB.connect db,username,password
    IBM_DB.set_option conn, {IBM_DB::SQL_ATTR_AUTOCOMMIT => IBM_DB::SQL_AUTOCOMMIT_OFF}, 1
    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (5, 'case5')"
    IBM_DB.set_option conn, {IBM_DB::SQL_ATTR_AUTOCOMMIT => IBM_DB::SQL_AUTOCOMMIT_ON}, 1
    if( !stmt )
      puts "case 5 insertion failed"
    end
  end

  def verifyCase5()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (5, 'case5')"
    if( !stmt )
      puts "Test Case 5 passed" #Insertion should fail as case5 transaction was committed
    end
  end

  # Check for clean transaction with Autocommit OFF and autocommit turned ON after transaction complete. Autocommit setting triggered from IBM_DB.autocommit
  def case6()
    conn = IBM_DB.connect db,username,password
    IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF
    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (6, 'case6')"
    IBM_DB.autocommit conn, IBM_DB::SQL_AUTOCOMMIT_ON
    if( !stmt )
      puts "case 6 insertion failed"
    end
  end

  def verifyCase6()
    conn = IBM_DB.connect db,username,password

    stmt = IBM_DB.exec conn, "insert into dealloctab(id, name) values (6, 'case6')"
    if( !stmt )
      puts "Test Case 6 passed" #Insertion should fail as case6 transaction was committed
    end
  end

  def test_connect_deallocator_rollsback_active_transaction
    assert_expect do
      prepareDB()

      case1()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase1()

      case2()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase2()

      case3()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase3()

      case4()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase4()

      case5()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase5()

      case6()
      GC::start #Need to start GC explicitly so that objects created in previous case call are garbage collected
      verifyCase6()
      
      cleanDB()
    end
  end
end

__END__
__LUW_EXPECTED__
Test Case 1 passed
Test Case 2 passed
Test Case 3 passed
Test Case 4 passed
Test Case 5 passed
Test Case 6 passed
__ZOS_EXPECTED__
Test Case 1 passed
Test Case 2 passed
Test Case 3 passed
Test Case 4 passed
Test Case 5 passed
Test Case 6 passed
__SYSTEMI_EXPECTED__
Test Case 1 passed
Test Case 2 passed
Test Case 3 passed
Test Case 4 passed
Test Case 5 passed
Test Case 6 passed
