# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2008,2009
#

class TestIbmDb < Test::Unit::TestCase

	def test_trusted_context_pconnect
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
		
		userBefore = ""

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
			
			# Making Persistance Trusted connection.
			conn_options = {IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT => IBM_DB::SQL_TRUE}			
			tc_options = {IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID => tc_user, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_PASSWORD => tc_pass}

			dsn = "DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};PROTOCOL=TCPIP;UID=#{auth_user};PWD=#{auth_pass};"
      begin
			  tc_conn = IBM_DB.pconnect dsn, '', '', conn_options
      rescue
        tc_conn = false
      end
						
			if tc_conn
				puts "Trusted connection established."
				val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
				if val
					userBefore = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
					IBM_DB::set_option tc_conn, tc_options, 1
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
						puts IBM_DB.getErrormsg(tc_conn, IBM_DB::DB_CONN)
					end
				end
				IBM_DB.close tc_conn
			else
				puts "Trusted connection failed."
			end
			
			# Creating 10 Persistance connections and checking if trusted context is enabled (Uncataloged connections)
			for i in (1 .. 10)
        begin
				  tc_conn = IBM_DB::pconnect dsn, '', ''
        rescue
          tc_conn = false
        end
				if tc_conn
					val = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_USE_TRUSTED_CONTEXT, 1
					if val
						userAfter = IBM_DB.get_option tc_conn, IBM_DB::SQL_ATTR_TRUSTED_CONTEXT_USERID, 1
						if userBefore != userAfter
							puts "Explicit Trusted Connection succeeded."
						end
					end
				end
			end
			
			# Dropping database.
			# Make a connection
			begin
			  conn = IBM_DB::connect database, user, password
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
Trusted connection established.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "%s" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
__ZOS_EXPECTED__
Trusted connection established.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "%s" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
__SYSTEMI_EXPECTED__
Trusted connection established.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "%s" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
__IDS_EXPECTED__
Trusted connection established.
User has been switched.
[%s][%s][%s] SQL0551N  "%s" does not have the privilege to perform operation "%s" on object "%s.TRUSTED_TABLE".  SQLSTATE=42501 SQLCODE=-551
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
Explicit Trusted Connection succeeded.
