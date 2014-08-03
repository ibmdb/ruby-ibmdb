# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2008,2009
#

class TestIbmDb < Test::Unit::TestCase

	def test_trusted_context_connect
		sql_drop_role = "DROP ROLE role_01"
		sql_create_role = "CREATE ROLE role_01"
		
		sql_drop_trusted_context = "DROP TRUSTED CONTEXT ctx"
		
		sql_create_trusted_context = "CREATE TRUSTED CONTEXT ctx BASED UPON CONNECTION USING SYSTEM AUTHID "
		sql_create_trusted_context += auth_user
		sql_create_trusted_context += " ATTRIBUTES (ADDRESS '"
		sql_create_trusted_context += hostname
		sql_create_trusted_context += "') DEFAULT ROLE role_01 ENABLE WITH USE FOR "
		sql_create_trusted_context += tc_user
		
		sql_drop_table = "DROP TABLE trusted_table"
		sql_create_table = "CREATE TABLE trusted_table (i1 int,i2 int)"

		sql_select = "SELECT * FROM trusted_table"
		
		assert_expectf do
			# Make a connection
      begin
			  conn = IBM_DB.connect database, user, password
      rescue
        conn = false                          
      end

			if conn
				# Dropping the trusted_table, in case it exists
				result = IBM_DB.exec conn, sql_drop_trusted_context rescue nil
				
				# Dropping the trusted_table
				result = IBM_DB.exec conn, sql_drop_table rescue nil
				
				# Dropping Role.
				result = IBM_DB.exec conn, sql_drop_role rescue nil

				# Create the trusted_table
				result = IBM_DB.exec conn, sql_create_table

				# Populating table.
				values = [
					[10, 20],
					[20, 40]
				]
				sql_insert = "INSERT INTO trusted_table (i1, i2) VALUES (?, ?)"
				stmt = IBM_DB.prepare conn, sql_insert
			
				if stmt
					for value in values
						result = IBM_DB.execute stmt, value
					end
				end

				# Printing the values from table.
				rows = IBM_DB.exec conn, sql_select
				while (row = IBM_DB.fetch_array(rows))
					row.each {|x| print x, " -- " }
					puts ""
				end
	
				# Creating Role.
				result = IBM_DB.exec conn, sql_create_role
			
				# Granting permissions to role.
				sql_grant_permission = "GRANT INSERT ON TABLE trusted_table TO ROLE role_01"
				result = IBM_DB.exec conn, sql_grant_permission
			
				# Creating trusted context
				sql_create_trusted_context_01 = sql_create_trusted_context + " WITH AUTHENTICATION"
				result = IBM_DB.exec conn, sql_create_trusted_context_01
			
				# Closing connection
				IBM_DB.close conn
			else 
				puts "Connection failed."
			end

			conn_options = {IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT => IBM_DB::SQL_TRUE}
			tc_options = {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => tc_user, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => tc_pass}
			tc_all_options = {
				IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT => IBM_DB::SQL_TRUE, 
				IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => tc_user, 
				IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => tc_pass
			}
			dsn = "DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};PROTOCOL=TCPIP;UID=#{auth_user};PWD=#{auth_pass};"

			# Makeing normal connection and playing with it.
      begin
			  tc_conn = IBM_DB.connect dsn, '', ''
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Normal connection established."
				result = IBM_DB.set_option tc_conn, tc_options, 1
				puts IBM_DB.getErrormsg(tc_conn, IBM_DB::DB_CONN)
				if tc_conn
					IBM_DB.close tc_conn
				end
			end

      begin
			  tc_conn = IBM_DB.connect dsn, '', ''
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Normal connection established."
				result = IBM_DB.set_option tc_conn, tc_all_options, 1
				puts IBM_DB.conn_errormsg(tc_conn)
				if tc_conn
					IBM_DB.close tc_conn
				end
			end

      begin
			  tc_conn = IBM_DB.connect dsn, '', '', tc_all_options
      rescue
        tc_conn = false
      end

			if tc_conn
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					puts "Trusted connection succeeded."
					get_tc_user = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					if tc_user != get_tc_user
						puts "But trusted user is not switched."
					end
				end
				IBM_DB.close tc_conn
			end

			# Making trusted connection
      begin
			  tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					userBefore = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					result = IBM_DB.set_option tc_conn, tc_options, 1
					userAfter = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					if userBefore != userAfter
						puts "User has been switched."
						
						# Inserting into table using trusted_user.
						sql_insert = "INSERT INTO #{user}.trusted_table (i1, i2) VALUES (?, ?)"
						stmt = IBM_DB.prepare tc_conn, sql_insert
						result = IBM_DB.execute stmt, [300, 500]

						# Updating table using trusted_user.
						sql_update = "UPDATE #{user}.trusted_table set i1 = 400 WHERE i2 = 500"
						stmt = IBM_DB.exec tc_conn, sql_update
						puts IBM_DB.getErrormsg(tc_conn, IBM_DB.DB_CONN)
					end
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end

			# Making trusted connection and switching to fake user.
      begin
			  tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					IBM_DB.set_option tc_conn, {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => "fakeuser", IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => "fakepassword"}, 1

					sql_update = "UPDATE #{user}.trusted_table set i1 = 400 WHERE i2 = 500"
					stmt = IBM_DB.exec tc_conn, sql_update
					puts IBM_DB.getErrormsg(tc_conn, IBM_DB::DB_CONN)
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end

			# Making trusted connection and passing password first then user while switching.
      begin
			  tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			tc_options_reversed = {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => tc_pass, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => tc_user}

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					userBefore = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					IBM_DB::set_option tc_conn, tc_options_reversed, 1
					userAfter = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					if userBefore != userAfter
						puts "User has been switched."
					end
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end

			# Making trusted connection and passing password first then user while switching.
      begin
        tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			tc_user_options = {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => tc_user}
			tc_pass_options = {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => tc_pass}

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					userBefore = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					IBM_DB.set_option tc_conn, tc_pass_options, 1
					puts IBM_DB.getErrormsg(tc_conn, IBM_DB.DB_CONN)
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end

			# Making trusted connection and passing only user while switching when both user and password are required.
			begin
			  tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					IBM_DB.set_option tc_conn, tc_user_options, 1

					sql_update = "UPDATE #{user}.trusted_table set i1 = 400 WHERE i2 = 500"
					stmt = IBM_DB.exec tc_conn, sql_update
					puts IBM_DB.getErrormsg(tc_conn, IBM_DB::DB_CONN)
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end

			# Make a connection
			begin
			  conn = IBM_DB.connect database, user, password
      rescue
        conn = false
      end

			if conn
				# Dropping the trusted context, in case it exists
				result = IBM_DB.exec conn, sql_drop_trusted_context rescue nil

				# Dropping Role.
				result = IBM_DB.exec conn, sql_drop_role rescue nil

				# Creating Role.
				result = IBM_DB.exec conn, sql_create_role
			
				# Granting permissions to role.
				sql_grant_permission = "GRANT UPDATE ON TABLE trusted_table TO ROLE role_01"
				result = IBM_DB.exec conn, sql_grant_permission
			
				# Creating trusted context
				sql_create_trusted_context_01 = sql_create_trusted_context + " WITHOUT AUTHENTICATION"
				result = IBM_DB.exec conn, sql_create_trusted_context_01
				
				# Closing connection
				IBM_DB.close conn
			else 
				puts "Connection failed."
			end	

			# Making trusted connection
			begin
			  tc_conn = IBM_DB.connect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end

			if tc_conn
				puts "Trusted connection succeeded."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					userBefore = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					IBM_DB::set_option tc_conn, tc_user_options, 1
					userAfter = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					if userBefore != userAfter
						puts "User has been switched."
						
						# Inserting into table using trusted_user.
						sql_insert = "INSERT INTO #{user}.trusted_table (i1, i2) VALUES (300, 500)"
						stmt = IBM_DB.exec tc_conn, sql_insert
						puts IBM_DB.getErrormsg(tc_conn, IBM_DB::DB_CONN)

						# Updating table using trusted_user.
						sql_update = "UPDATE #{user}.trusted_table set i1 = 400 WHERE i2 = 20"
						stmt = IBM_DB.exec tc_conn, sql_update
					end
				end
				IBM_DB.close tc_conn
			else
				puts "Connection failed."
			end
		
			
			# Make a connection
			begin
			  conn = IBM_DB.connect database, user, password
      rescue
        conn = false
      end

			if conn
				# Printing the values from table.
				rows = IBM_DB.exec conn, sql_select
				while (row = IBM_DB.fetch_array(rows))
					row.each {|x| print x, " -- " }
					puts ""
				end

				# Dropping the trusted_table, in case it exists
				result = IBM_DB.exec conn, sql_drop_trusted_context rescue nil
				
				# Dropping the trusted_table
				result = IBM_DB.exec conn, sql_drop_table rescue nil
				
				# Dropping Role.
				result = IBM_DB.exec conn, sql_drop_role rescue nil
				
				# Closing connection
				IBM_DB.close conn
			else 
				puts "Connection failed."
			end
		end
	end
end

__END__
__LUW_EXPECTED__
10 -- 20 -- 
20 -- 40 -- 
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Trusted connection succeeded.
But trusted user is not switched.
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "UPDATE" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
Trusted connection succeeded.
[%s][%s][%s] SQL30082N  Security processing failed with reason "24" ("USERNAME AND/OR PASSWORD INVALID").  SQLSTATE=08001 SQLCODE=-30082
Trusted connection succeeded.
User has been switched.
Trusted connection succeeded.
[%s][%s] CLI0198E  Missing trusted context userid. SQLSTATE=HY010
Trusted connection succeeded.
[%s][%s][%s] SQL20361N  The switch user request using authorization ID "%s" within trusted context "CTX" failed with reason code "2".  SQLSTATE=42517 SQLCODE=-20361
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "INSERT" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
400 -- 20 -- 
20 -- 40 -- 
300 -- 500 --
__ZOS_EXPECTED__
10 -- 20 -- 
20 -- 40 -- 
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Trusted connection succeeded.
But trusted user is not switched.
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "UPDATE" on object "%s.TRUSTED_TABLE". SQLSTATE=42501 SQLCODE=-551
Trusted connection succeeded.
[%s][%s][%s] SQL30082N  Security processing failed with reason "24" ("USERNAME AND/OR PASSWORD INVALID").  SQLSTATE=08001 SQLCODE=-30082
Trusted connection succeeded.
User has been switched.
Trusted connection succeeded.
[%s][%s] CLI0198E  Missing trusted context userid. SQLSTATE=HY010
Trusted connection succeeded.
[%s][%s][%s] SQL20361N  The switch user request using authorization ID "%s" within trusted context "CTX" failed with reason code "2".  SQLSTATE=42517 SQLCODE=-20361
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "INSERT" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
400 -- 20 -- 
20 -- 40 -- 
300 -- 500 --
__SYSTEMI_EXPECTED__
10 -- 20 -- 
20 -- 40 -- 
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Trusted connection succeeded.
But trusted user is not switched.
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "UPDATE" on object "%s.TRUSTED_TABLE". SQLSTATE=42501 SQLCODE=-551
Trusted connection succeeded.
[%s][%s][%s] SQL30082N  Security processing failed with reason "24" ("USERNAME AND/OR PASSWORD INVALID").  SQLSTATE=08001 SQLCODE=-30082
Trusted connection succeeded.
User has been switched.
Trusted connection succeeded.
[%s][%s] CLI0198E  Missing trusted context userid. SQLSTATE=HY010
Trusted connection succeeded.
[%s][%s][%s] SQL20361N  The switch user request using authorization ID "%s" within trusted context "CTX" failed with reason code "2".  SQLSTATE=42517 SQLCODE=-20361
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "INSERT" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
400 -- 20 -- 
20 -- 40 -- 
300 -- 500 --
__IDS_EXPECTED__
10 -- 20 -- 
20 -- 40 -- 
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Normal connection established.
[%s][%s] CLI0197E  A trusted context is not enabled on this connection. Invalid attribute value. SQLSTATE=HY010
Trusted connection succeeded.
But trusted user is not switched.
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "UPDATE" on object "%s.TRUSTED_TABLE". SQLSTATE=42501 SQLCODE=-551
Trusted connection succeeded.
[%s][%s][%s] SQL30082N  Security processing failed with reason "24" ("USERNAME AND/OR PASSWORD INVALID").  SQLSTATE=08001 SQLCODE=-30082
Trusted connection succeeded.
User has been switched.
Trusted connection succeeded.
[%s][%s] CLI0198E  Missing trusted context userid. SQLSTATE=HY010
Trusted connection succeeded.
[%s][%s][%s] SQL20361N  The switch user request using authorization ID "%s" within trusted context "CTX" failed with reason code "2".  SQLSTATE=42517 SQLCODE=-20361
Trusted connection succeeded.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "INSERT" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
400 -- 20 -- 
20 -- 40 -- 
300 -- 500 --
