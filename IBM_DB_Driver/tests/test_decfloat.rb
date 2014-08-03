# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_decfloat
    assert_expect do
      conn = IBM_DB::connect database, user, password
      
      if conn
        IBM_DB::autocommit conn, IBM_DB::SQL_AUTOCOMMIT_OFF

	# Drop table stockprice if it already exists
	drop = 'DROP TABLE STOCKPRICE'
	result = IBM_DB::exec(conn, drop) rescue nil

	# Create table stockprice
	create = 'CREATE TABLE STOCKPRICE (id SMALLINT NOT NULL, company VARCHAR(30), Stockshare DECIMAL(7,2), stockprice DECFLOAT(16))'
	result = IBM_DB::exec conn, create

	# Insert using direct execute without prepare
	insertVal = "INSERT INTO STOCKPRICE (id, company, Stockshare, stockprice) VALUES (10,'Megadeth' , 100.002, 990.356)"
	result = IBM_DB::exec conn, insertVal

	# Populate the Stockprice Table
	stockprice = [
		[20, "Zaral", 102.205, "100.234"],
		[30, "Megabyte", 98.65, "1002.112"],
		[40, "Visarsoft",123.34,"1652.345"],
		[50, "Mailersoft",134.22,"1643.126"],
		[60, "Kaerci",100.97,9876.765]
		]

	insert = 'INSERT INTO STOCKPRICE (id, company, Stockshare,stockprice) VALUES (?,?,?,?)'
	stmt = IBM_DB::prepare conn, insert
	if stmt
  		for company in stockprice
			result = IBM_DB::execute stmt, company
  		end
	end

	# Insert using Binding of Parameters explicitly
	
	insert = "INSERT INTO STOCKPRICE (id, company, Stockshare,stockprice) VALUES (70,'Nirvana',100.1234,?)"
        stmt = IBM_DB::prepare conn, insert

	stockpric = 100.567
	IBM_DB::bind_param( stmt , 1 , 'stockpric'  )

	result = IBM_DB::execute stmt 

	# Select the result back from the table
	query = 'SELECT id, company, Stockshare, stockprice FROM STOCKPRICE ORDER BY id'
	stmt = IBM_DB::prepare conn, query
	IBM_DB::execute stmt
	while (data = IBM_DB::fetch_both stmt)
		puts "#{data[0]}  #{data[1]}  #{data[2]}  #{data[3]}"
	end

      else
        puts "Connection failed."
      end
    end
  end
end

__END__
__LUW_EXPECTED__
10  Megadeth  0.1E3  0.990356E3
20  Zaral  0.1022E3  0.100234E3
30  Megabyte  0.9865E2  0.1002112E4
40  Visarsoft  0.12334E3  0.1652345E4
50  Mailersoft  0.13422E3  0.1643126E4
60  Kaerci  0.10097E3  0.9876765E4
70  Nirvana  0.10012E3  0.100567E3
__ZOS_EXPECTED__
10  Megadeth  0.1E3  0.990356E3
20  Zaral  0.1022E3  0.100234E3
30  Megabyte  0.9865E2  0.1002112E4
40  Visarsoft  0.12334E3  0.1652345E4
50  Mailersoft  0.13422E3  0.1643126E4
60  Kaerci  0.10097E3  0.9876765E4
70  Nirvana  0.10012E3  0.100567E3
