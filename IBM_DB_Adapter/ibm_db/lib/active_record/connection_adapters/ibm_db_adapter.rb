# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007, 2008, 2009, 2010           |
# +----------------------------------------------------------------------+
# |  Authors: Antonio Cangiano <cangiano@ca.ibm.com>                     |
# |         : Mario Ds Briggs  <mario.briggs@in.ibm.com>                 |
# |         : Praveen Devarao  <praveendrl@in.ibm.com>                   |
# +----------------------------------------------------------------------+

require 'active_record/connection_adapters/abstract_adapter'
require 'arel/visitors/bind_visitor'

module ActiveRecord
  class Relation
    def insert(values)
      primary_key_value = nil

      if primary_key && Hash === values
        primary_key_value = values[values.keys.find { |k|
          k.name == primary_key
        }]

        if !primary_key_value && connection.prefetch_primary_key?(klass.table_name)
          primary_key_value = connection.next_sequence_value(klass.sequence_name)
          values[klass.arel_table[klass.primary_key]] = primary_key_value
        end
      end

      im = arel.create_insert
      im.into @table

      conn = @klass.connection

      substitutes = values.sort_by { |arel_attr,_| arel_attr.name }
      binds       = substitutes.map do |arel_attr, value|
        [@klass.columns_hash[arel_attr.name], value]
      end

      substitutes.each_with_index do |tuple, i|
        tuple[1] = conn.substitute_at(binds[i][0], i)
      end

      if values.empty? # empty insert
        im.values = Arel.sql(connection.empty_insert_statement_value(klass.primary_key))
      else
        im.insert substitutes
      end

      conn.insert(
        im,
        'SQL',
        primary_key,
        primary_key_value,
        nil,
        binds)
    end
  end

  class Base
    # Method required to handle LOBs and XML fields. 
    # An after save callback checks if a marker has been inserted through
    # the insert or update, and then proceeds to update that record with 
    # the actual large object through a prepared statement (param binding).
    after_save :handle_lobs
    def handle_lobs()
      if self.class.connection.kind_of?(ConnectionAdapters::IBM_DBAdapter)
        # Checks that the insert or update had at least a BLOB, CLOB or XML field
        self.class.connection.sql.each do |clob_sql|
          if clob_sql =~ /BLOB\('(.*)'\)/i || 
             clob_sql =~ /@@@IBMTEXT@@@/i || 
             clob_sql =~ /@@@IBMXML@@@/i ||
             clob_sql =~ /@@@IBMBINARY@@@/i 
            update_query = "UPDATE #{self.class.table_name} SET ("
            counter = 0
            values = []
            params = []
            # Selects only binary, text and xml columns
            self.class.columns.select{|col| col.type == :binary || 
                                            col.type == :text || 
                                            col.type == :xml}.each do |col|
              # Adds the selected columns to the query
              if counter == 0
                update_query << "#{col.name}"
              else
                update_query << ",#{col.name}"
              end

              # Add a '?' for the parameter or a NULL if the value is nil or empty 
              # (except for a CLOB field where '' can be a value)
              if self[col.name].nil? || 
                 self[col.name] == {} || 
                 self[col.name] == [] ||
                (self[col.name] == '' && col.type != :text)
                params << 'NULL'
              else
                if self.class.serialized_attributes[col.name]
                  values << YAML.dump(self[col.name])
                else
                  values << self[col.name]
                end
                params << '?'
              end
              counter += 1
            end
            # no subsequent update is required if no relevant columns are found
            next if counter == 0

            update_query << ") = "
            # IBM_DB accepts 'SET (column) = NULL'  but not (NULL),
            # therefore the sql needs to be changed for a single NULL field.
            if params.size==1 && params[0] == 'NULL'
              update_query << "NULL"
            else
              update_query << "(" + params.join(',') + ")"
            end

            update_query << " WHERE #{self.class.primary_key} = ?"
            values << self[self.class.primary_key.downcase]

            begin
              unless stmt = IBM_DB.prepare(self.class.connection.connection, update_query)
                error_msg = IBM_DB.getErrormsg( self.class.connection.connection, IBM_DB::DB_CONN )
                if error_msg && !error_msg.empty?
                  raise "Statement prepare for updating LOB/XML column failed : #{error_msg}"
                else
                  raise StandardError.new('An unexpected error occurred during update of LOB/XML column')
                end
              end
              self.class.connection.log_query(update_query,'update of LOB/XML field(s)in handle_lobs')

              # rollback any failed LOB/XML field updates (and remove associated marker)
              unless IBM_DB.execute(stmt, values)
                error_msg = "Failed to insert/update LOB/XML field(s) due to: #{IBM_DB.getErrormsg( stmt, IBM_DB::DB_STMT )}"
                self.class.connection.execute("ROLLBACK")
                raise error_msg
              end
            rescue StandardError => error
              raise error
            ensure
              IBM_DB.free_stmt(stmt) if stmt
            end
          end # if clob_sql
        end #connection.sql.each
        self.class.connection.handle_lobs_triggered = true
      end # if connection.kind_of?
    end # handle_lobs
    private :handle_lobs

    # Establishes a connection to a specified database using the credentials provided
    # with the +config+ argument. All the ActiveRecord objects will use this connection
    def self.ibm_db_connection(config)
      # Attempts to load the Ruby driver IBM databases
      # while not already loaded or raises LoadError in case of failure.
      begin
        require 'ibm_db' unless defined? IBM_DB
      rescue LoadError
        raise LoadError, "Failed to load IBM_DB Ruby driver."
      end

      if( config.has_key?(:parameterized) && config[:parameterized] == true )
        require 'active_record/connection_adapters/ibm_db_pstmt'
      end

	  # Check if class TableDefinition responds to indexes method to determine if we are on AR 3 or AR 4.
	  # This is a interim hack ti ensure backward compatibility. To remove as we move out of AR 3 support or have a better way to determine which version of AR being run against.
	  checkClass = ActiveRecord::ConnectionAdapters::TableDefinition.new(nil)
	  if(checkClass.respond_to?(:indexes))
	    isAr3 = false
	  else
	    isAr3 = true
	  end
      # Converts all +config+ keys to symbols
      config = config.symbolize_keys

      # Flag to decide if quoted literal replcement should take place. By default it is ON. Set it to OFF if using Pstmt
      set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_ON

      # Retrieves database user credentials from the +config+ hash
      # or raises ArgumentError in case of failure.
      if !config.has_key?(:username) || !config.has_key?(:password)
        raise ArgumentError, "Missing argument(s): Username/Password for #{config[:database]} is not specified"
      else
        if(config[:username].to_s.nil? || config[:password].to_s.nil?)
          raise ArgumentError, "Username/Password cannot be nil"
        end
        username = config[:username].to_s
        password = config[:password].to_s
      end

      if(config.has_key?(:dbops) && config[:dbops] == true)
        return ConnectionAdapters::IBM_DBAdapter.new(nil, isAr3, logger, config, {})
      end

      # Retrieves the database alias (local catalog name) or remote name
      # (for remote TCP/IP connections) from the +config+ hash
      # or raises ArgumentError in case of failure.
      if config.has_key?(:database)
        database = config[:database].to_s
      else
        raise ArgumentError, "Missing argument: a database name needs to be specified."
      end

      # Providing default schema (username) when not specified
      config[:schema] = config.has_key?(:schema) ? config[:schema].to_s : config[:username].to_s

      if(config.has_key?(:parameterized) && config[:parameterized] == true )
        set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF
      end

      # Extract connection options from the database configuration
      # (in support to formatting, audit and billing purposes):
      # Retrieve database objects fields in lowercase
      conn_options = {IBM_DB::ATTR_CASE => IBM_DB::CASE_LOWER}
      config.each do |key, value|
        if !value.nil?
          case key
            when :app_user        # Set connection's user info
              conn_options[IBM_DB::SQL_ATTR_INFO_USERID]     = value
            when :account         # Set connection's account info
              conn_options[IBM_DB::SQL_ATTR_INFO_ACCTSTR]    = value
            when :application     # Set connection's application info
              conn_options[IBM_DB::SQL_ATTR_INFO_APPLNAME]   = value
            when :workstation     # Set connection's workstation info
              conn_options[IBM_DB::SQL_ATTR_INFO_WRKSTNNAME] = value
          end    
        end
      end

      begin
        # Checks if a host name or address has been specified. If so, this implies a TCP/IP connection
        # Returns IBM_DB.Connection object upon succesful DB connection to the database
        # If otherwise the connection fails, +false+ is returned
        if config.has_key?(:host)
          # Retrieves the host address/name
          host = config[:host]
          # A net address connection requires a port. If no port has been specified, 50000 is used by default
          port = config[:port] || 50000
          # Connects to the database specified using the hostname, port, authentication type, username and password info
          # Starting with DB2 9.1FP5 secure connections using SSL are supported. 
          # On the client side using CLI this is supported from CLI version V95FP2 and onwards.
          # This feature is set by specifying SECURITY=SSL in the connection string.
          # Below connection string is constructed and SECURITY parameter is appended if the user has specified the :security option
          conn_string = "DRIVER={IBM DB2 ODBC DRIVER};\
                         DATABASE=#{database};\
                         HOSTNAME=#{host};\
                         PORT=#{port};\
                         PROTOCOL=TCPIP;\
                         UID=#{username};\
                         PWD=#{password};"
          conn_string << "SECURITY=#{config[:security]};" if config.has_key?(:security)
          conn_string << "AUTHENTICATION=#{config[:authentication]};" if config.has_key?(:authentication)
          conn_string << "CONNECTTIMEOUT=#{config[:timeout]};" if config.has_key?(:timeout)
        
          connection = IBM_DB.connect( conn_string, '', '', conn_options, set_quoted_literal_replacement )
        else
          # No host implies a local catalog-based connection: +database+ represents catalog alias
          connection = IBM_DB.connect( database, username, password, conn_options,  set_quoted_literal_replacement )
        end
      rescue StandardError => connect_err
        raise "Failed to connect to [#{database}] due to: #{connect_err}"
      end
      # Verifies that the connection was successful
      if connection
        # Creates an instance of *IBM_DBAdapter* based on the +connection+
        # and credentials provided in +config+
        ConnectionAdapters::IBM_DBAdapter.new(connection, isAr3, logger, config, conn_options)
      else
        # If the connection failure was not caught previoulsy, it raises a Runtime error
        raise "An unexpected error occured during connect attempt to [#{database}]"
      end
    end # method self.ibm_db_connection

    def self.ibmdb_connection(config)
	  #Method to support alising of adapter name as ibmdb [without underscore]
      self.ibm_db_connection(config)
    end
  end # class Base

  module ConnectionAdapters
    module SchemaStatements
      def create_table_definition(name, temporary, options,as = nil)
        TableDefinition.new self, name, temporary, options
      end
    end
    class IBM_DBColumn < Column

      # Casts value (which is a String) to an appropriate instance
      def type_cast(value)
        # Casts the database NULL value to nil
        return nil if value == 'NULL'
        # Invokes parent's method for default casts
        super
      end

      # Used to convert from BLOBs to Strings
      def self.binary_to_string(value)
        # Returns a string removing the eventual BLOB scalar function
        value.to_s.gsub(/"SYSIBM"."BLOB"\('(.*)'\)/i,'\1')
      end

       private
      # Mapping IBM data servers SQL datatypes to Ruby data types
      def simplified_type(field_type)
        case field_type
          # if +field_type+ contains 'for bit data' handle it as a binary
          when /for bit data/i
            :binary
          when /smallint/i
            :boolean
          when /int|serial/i
            :integer
          when /decimal|numeric|decfloat/i
            :decimal
          when /float|double|real/i
            :float
          when /timestamp|datetime/i
            :timestamp
          when /time/i
            :time
          when /date/i
            :date
          when /vargraphic/i
            :vargraphic
          when /graphic/i
            :graphic
          when /clob|text/i
            :text
          when /xml/i
            :xml
          when /blob|binary/i
            :binary
          when /char/i
            :string
          when /boolean/i
            :boolean
          when /rowid/i  # rowid is a supported datatype on z/OS and i/5
            :rowid
        end
      end # method simplified_type
    end #class IBM_DBColumn

    class Table
      
      #Method to parse the passed arguments and create the ColumnDefinition object of the specified type
      def ibm_parse_column_attributes_args(type, *args)
        options = {}
        if args.last.is_a?(Hash) 
          options = args.delete_at(args.length-1)
        end
        args.each do | name | 
          column name,type.to_sym,options
        end # end args.each
      end
      private :ibm_parse_column_attributes_args
    
      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type xml 
      #This method is different as compared to def char (sql is being issued explicitly 
      #as compared to def char where method column(which will generate the sql is being called)
      #in order to handle the DEFAULT and NULL option for the native XML datatype
      def xml(*args ) 
        options = {}
        if args.last.is_a?(Hash) 
          options = args.delete_at(args.length-1)
        end
        sql_segment = "ALTER TABLE #{@base.quote_table_name(@table_name)} ADD COLUMN "
        args.each do | name | 
          sql =  sql_segment + " #{@base.quote_column_name(name)} xml"
          @base.execute(sql,"add_xml_column")
        end  
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type double
      def double(*args)
        ibm_parse_column_attributes_args('double',*args)
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type decfloat
      def decfloat(*args)
        ibm_parse_column_attributes_args('decfloat',*args)
        return self
      end

      def graphic(*args)
        ibm_parse_column_attributes_args('graphic',*args)
        return self
      end

      def vargraphic(*args)
        ibm_parse_column_attributes_args('vargraphic',*args)
        return self
      end

      def bigint(*args)
        ibm_parse_column_attributes_args('bigint',*args)
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type char [character]
      def char(*args)
        ibm_parse_column_attributes_args('char',*args)
        return self
      end
      alias_method :character, :char
    end

    class TableDefinition

      def initialize(base, name=nil, temporary=nil, options=nil)
        if(self.respond_to?(:indexes))
          @ar3 = false
        else
          @ar3 = true
        end
        @columns = []
        @columns_hash = {}
        @indexes = {}
        @base = base
        @temporary = temporary
        @options = options
        @name = name
      end

      def native
        @base.native_database_types
      end
 
      #Method to parse the passed arguments and create the ColumnDefinition object of the specified type
      def ibm_parse_column_attributes_args(type, *args)
        options = {}
        if args.last.is_a?(Hash)
          options = args.delete_at(args.length-1)
        end
        args.each do | name |
          column(name,type,options)
        end
      end
      private :ibm_parse_column_attributes_args

      #Method to support the new syntax of rails 2.0 migrations for columns of type xml 
      def xml(*args )
        ibm_parse_column_attributes_args('xml', *args)
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type double
      def double(*args)
        ibm_parse_column_attributes_args('double',*args)
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type decfloat
      def decfloat(*args)
        ibm_parse_column_attributes_args('decfloat',*args)
        return self
      end

      def graphic(*args)
        ibm_parse_column_attributes_args('graphic',*args)
        return self
      end

      def vargraphic(*args)
        ibm_parse_column_attributes_args('vargraphic',*args)
        return self
      end

      def bigint(*args)
        ibm_parse_column_attributes_args('bigint',*args)
        return self
      end

      #Method to support the new syntax of rails 2.0 migrations (short-hand definitions) for columns of type char [character]
      def char(*args)
        ibm_parse_column_attributes_args('char',*args)
        return self
      end
      alias_method :character, :char

      # Overrides the abstract adapter in order to handle
      # the DEFAULT option for the native XML datatype
      def column(name, type, options ={})
        # construct a column definition where @base is adaptor instance
        if(@ar3)
          column = ColumnDefinition.new(@base, name, type)
        else
          column = ColumnDefinition.new(name, type)
        end
        # DB2 does not accept DEFAULT NULL option for XML
        # for table create, but does accept nullable option
        unless type.to_s == 'xml'
          column.null    = options[:null]
          column.default = options[:default]
        else
          column.null    = options[:null]
          # Override column object's (instance of ColumnDefinition structure)
          # to_s which is expected to return the create_table SQL fragment
          # and bypass DEFAULT NULL option while still appending NOT NULL
          def column.to_s
            sql = "#{base.quote_column_name(name)} #{type}"
            unless self.null == nil
              sql << " NOT NULL" if (self.null == false)
            end
            return sql
          end
        end

        column.scale     = options[:scale]      if options[:scale]
        column.precision = options[:precision]  if options[:precision]
        # append column's limit option and yield native limits
        if options[:limit]
          column.limit   = options[:limit]
        elsif @base.native_database_types[type.to_sym]
          column.limit   = @base.native_database_types[type.to_sym][:limit] if @base.native_database_types[type.to_sym].has_key? :limit
        end

        unless @columns.nil? or @columns.include? column
          @columns << column 
        end

        @columns_hash[name] = column

        return self
      end
    end

    # The IBM_DB Adapter requires the native Ruby driver (ibm_db)
    # for IBM data servers (ibm_db.so).
    # +config+ the hash passed as an initializer argument content:
    # == mandatory parameters 
    #   adapter:         'ibm_db'        // IBM_DB Adapter name
    #   username:        'db2user'       // data server (database) user
    #   password:        'secret'        // data server (database) password
    #   database:        'ARUNIT'        // remote database name (or catalog entry alias)
    # == optional (highly recommended for data server auditing and monitoring purposes)
    #   schema:          'rails123'      // name space qualifier
    #   account:         'tester'        // OS account (client workstation)
    #   app_user:        'test11'        // authenticated application user
    #   application:     'rtests'        // application name
    #   workstation:     'plato'         // client workstation name
    # == remote TCP/IP connection (required when no local database catalog entry available)
    #   host:            'socrates'      // fully qualified hostname or IP address
    #   port:            '50000'         // data server TCP/IP port number
    #   security:        'SSL'           // optional parameter enabling SSL encryption -
    #                                    // - Available only from CLI version V95fp2 and above
    #   authentication:  'SERVER'        // AUTHENTICATION type which the client uses - 
    #                                    // - to connect to the database server. By default value is SERVER
    #   timeout:         10              // Specifies the time in seconds (0 - 32767) to wait for a reply from server -
    #                                    //- when trying to establish a connection before generating a timeout
    # == Parameterized Queries Support
    #   parameterized:  false            // Specifies if the prepared statement support of 
    #                                    //- the IBM_DB Adapter is to be turned on or off
    # 
    # When schema is not specified, the username value is used instead.
    # The default setting of parameterized is false.
    # 
    class IBM_DBAdapter < AbstractAdapter
      attr_reader :connection, :servertype
      attr_accessor :sql,:handle_lobs_triggered, :sql_parameter_values
      attr_reader :schema, :app_user, :account, :application, :workstation
      attr_reader :pstmt_support_on, :set_quoted_literal_replacement

      # Name of the adapter
      def adapter_name
        'IBM_DB'
      end

      class BindSubstitution < Arel::Visitors::IBM_DB # :nodoc:
          include Arel::Visitors::BindVisitor
      end

      def initialize(connection, ar3, logger, config, conn_options)
        # Caching database connection configuration (+connect+ or +reconnect+ support)
        @connection       = connection
		@isAr3            = ar3
        @conn_options     = conn_options
        @database         = config[:database]
        @username         = config[:username]
        @password         = config[:password]
        if config.has_key?(:host)
          @host           = config[:host]
          @port           = config[:port] || 50000 # default port
        end
        @schema           = config[:schema]
        @security         = config[:security] || nil
        @authentication   = config[:authentication] || nil
        @timeout          = config[:timeout] || 0  # default timeout value is 0

        if( config.has_key?(:parameterized) && config[:parameterized] == true )
          @pstmt_support_on = true
          @set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF
        else
          @pstmt_support_on = false
          @set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_ON
        end
        
        @app_user = @account = @application = @workstation = nil
        # Caching database connection options (auditing and billing support)
        @app_user         = conn_options[:app_user]     if conn_options.has_key?(:app_user)
        @account          = conn_options[:account]      if conn_options.has_key?(:account)
        @application      = conn_options[:application]  if conn_options.has_key?(:application)
        @workstation      = conn_options[:workstation]  if conn_options.has_key?(:workstation)
        
        @sql                  = []
        @sql_parameter_values = [] #Used only if pstmt support is turned on

        @handle_lobs_triggered = false

        # Calls the parent class +ConnectionAdapters+' initializer
        # which sets @connection, @logger, @runtime and @last_verification
        super(@connection, logger)

        if @connection
          server_info = IBM_DB.server_info( @connection )
          if( server_info )
            case server_info.DBMS_NAME
              when /DB2\//i             # DB2 for Linux, Unix and Windows (LUW)
                case server_info.DBMS_VER
                  when /09.07/i          # DB2 Version 9.7 (Cobra)
                    @servertype = IBM_DB2_LUW_COBRA.new(self, @isAr3)
                  when /10./i #DB2 version 10.1 and above
                    @servertype = IBM_DB2_LUW_COBRA.new(self, @isAr3)
                  else                  # DB2 Version 9.5 or below
                    @servertype = IBM_DB2_LUW.new(self, @isAr3)
                end
              when /DB2/i               # DB2 for zOS
                case server_info.DBMS_VER
                  when /09/             # DB2 for zOS version 9 and version 10
                    @servertype = IBM_DB2_ZOS.new(self, @isAr3)
                  when /10/
                    @servertype = IBM_DB2_ZOS.new(self, @isAr3)
                  when /08/             # DB2 for zOS version 8
                    @servertype = IBM_DB2_ZOS_8.new(self, @isAr3)
                  else                  # DB2 for zOS version 7
                    raise "Only DB2 z/OS version 8 and above are currently supported"
                end
              when /AS/i                # DB2 for i5 (iSeries)
                @servertype = IBM_DB2_I5.new(self, @isAr3)
              when /IDS/i               # Informix Dynamic Server
                @servertype = IBM_IDS.new(self, @isAr3)
              else
                log( "server_info", "Forcing servertype to LUW: DBMS name could not be retrieved. Check if your client version is of the right level")
                warn "Forcing servertype to LUW: DBMS name could not be retrieved. Check if your client version is of the right level"
                @servertype = IBM_DB2_LUW.new(self, @isAr3)
            end
          else
            error_msg = IBM_DB.getErrormsg( @connection, IBM_DB::DB_CONN )
            IBM_DB.close( @connection )
            raise "Cannot retrieve server information: #{error_msg}"
          end
        end

        # Executes the +set schema+ statement using the schema identifier provided
        @servertype.set_schema(@schema) if @schema && @schema != @username

        # Check for the start value for id (primary key column). By default it is 1
        if config.has_key?(:start_id)
          @start_id = config[:start_id]
        else
          @start_id = 1
        end

        #Check Arel version
        begin
          @arelVersion = Arel::VERSION.to_i
        rescue
          @arelVersion = 0
        end

        if(@arelVersion >=  3 )
          @visitor = Arel::Visitors::IBM_DB.new self
        end
      end

      # Optional connection attribute: database name space qualifier
      def schema=(name)
        unless name == @schema
          @schema = name
          @servertype.set_schema(@schema)
        end
      end

      # Optional connection attribute: authenticated application user
      def app_user=(name)
        unless name == @app_user
          option = {IBM_DB::SQL_ATTR_INFO_USERID => "#{name}"}
          if IBM_DB.set_option( @connection, option, 1 )
            @app_user = IBM_DB.get_option( @connection, IBM_DB::SQL_ATTR_INFO_USERID, 1 )
          end
        end
      end

      # Optional connection attribute: OS account (client workstation)
      def account=(name)
        unless name == @account
          option = {IBM_DB::SQL_ATTR_INFO_ACCTSTR => "#{name}"}
          if IBM_DB.set_option( @connection, option, 1 )
            @account = IBM_DB.get_option( @connection, IBM_DB::SQL_ATTR_INFO_ACCTSTR, 1 )
          end
        end
      end

      # Optional connection attribute: application name
      def application=(name)
        unless name == @application
          option = {IBM_DB::SQL_ATTR_INFO_APPLNAME => "#{name}"}
          if IBM_DB.set_option( @connection, option, 1 )
            @application = IBM_DB.get_option( @connection, IBM_DB::SQL_ATTR_INFO_APPLNAME, 1 )
          end
        end
      end

      # Optional connection attribute: client workstation name
      def workstation=(name)
        unless name == @workstation
          option = {IBM_DB::SQL_ATTR_INFO_WRKSTNNAME => "#{name}"}
          if IBM_DB.set_option( @connection, option, 1 )
            @workstation = IBM_DB.get_option( @connection, IBM_DB::SQL_ATTR_INFO_WRKSTNNAME, 1 )
          end
        end
      end

      def self.visitor_for(pool)
        Arel::Visitors::IBM_DB.new(pool)
      end
      
      def to_sql(arel, binds = [])
        if arel.respond_to?(:ast)
          visitor.accept(arel.ast) do
            quote(*binds.shift.reverse)
          end
        else
          arel
        end
      end

      # This adapter supports migrations.
      # Current limitations:
      # +rename_column+ is not currently supported by the IBM data servers
      # +remove_column+ is not currently supported by the DB2 for zOS data server
      # Tables containing columns of XML data type do not support +remove_column+
      def supports_migrations?
        true
      end

      def supports_foreign_keys?
        false
      end

      # This Adapter supports DDL transactions.
      # This means CREATE TABLE and other DDL statements can be carried out as a transaction. 
      # That is the statements executed can be ROLLED BACK in case of any error during the process.
      def supports_ddl_transactions?
        true
      end

      def log_query(sql, name) #:nodoc:
        # Used by handle_lobs
        log(sql,name){}
      end

      #==============================================
      # CONNECTION MANAGEMENT
      #==============================================

      # Tests the connection status
      def active?
        IBM_DB.active @connection
        rescue
          false
      end

      # Private method used by +reconnect!+.
      # It connects to the database with the initially provided credentials
      def connect
        # If the type of connection is net based
        if(@username.nil? || @password.nil?)
          raise ArgumentError, "Username/Password cannot be nil"
        end

        begin
          if @host
            @conn_string = "DRIVER={IBM DB2 ODBC DRIVER};\
                            DATABASE=#{@database};\
                            HOSTNAME=#{@host};\
                            PORT=#{@port};\
                            PROTOCOL=TCPIP;\
                            UID=#{@username};\
                            PWD=#{@password};"
            @conn_string << "SECURITY=#{@security};" if @security
            @conn_string << "AUTHENTICATION=#{@authentication};" if @authentication
            @conn_string << "CONNECTTIMEOUT=#{@timeout};"
            # Connects and assigns the resulting IBM_DB.Connection to the +@connection+ instance variable
            @connection = IBM_DB.connect(@conn_string, '', '', @conn_options, @set_quoted_literal_replacement)
          else
            # Connects to the database using the local alias (@database)
            # and assigns the connection object (IBM_DB.Connection) to @connection
            @connection = IBM_DB.connect(@database, @username, @password, @conn_options, @set_quoted_literal_replacement)
          end
        rescue StandardError => connect_err
          warn "Connection to database #{@database} failed: #{connect_err}"
          @connection = false
        end
        # Sets the schema if different from default (username)
        if @schema && @schema != @username
          @servertype.set_schema(@schema)
        end
      end
      private :connect

      # Closes the current connection and opens a new one
      def reconnect!
        disconnect!
        connect
      end

      # Closes the current connection
      def disconnect!
        # Attempts to close the connection. The methods will return:
        # * true if succesfull
        # * false if the connection is already closed
        # * nil if an error is raised
        return nil if @connection.nil? || @connection == false
        IBM_DB.close(@connection) rescue nil
      end

      #==============================================
      # DATABASE STATEMENTS
      #==============================================

      def create_table(name, options = {})
        @servertype.setup_for_lob_table
        super
        
        #Table definition is complete only when a unique index is created on the primarykey column for DB2 V8 on zOS
        
        #create index on id column if options[:id] is nil or id ==true
        #else check if options[:primary_key]is not nil then create an unique index on that column
        if  !options[:id].nil? || !options[:primary_key].nil?
          if (!options[:id].nil? && options[:id] == true)
            @servertype.create_index_after_table(name,"id")
          elsif !options[:primary_key].nil?
            @servertype.create_index_after_table(name,options[:primary_key].to_s)
          end
        else
          @servertype.create_index_after_table(name,"id")
        end 
      end

      # Returns an array of hashes with the column names as keys and
      # column values as values. +sql+ is the select query, 
      # and +name+ is an optional description for logging
      def prepared_select(sql_param_hash, name = nil)
        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"}

        results = []
        # Invokes the method +prepare+ in order prepare the SQL
        # IBM_DB.Statement is returned from which the statement is executed and results fetched
        pstmt = prepare(sql_param_hash["sqlSegment"], name)
        if(execute_prepared_stmt(pstmt, sql_param_hash["paramArray"]))
          begin
            results = @servertype.select(pstmt)
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(pstmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during data retrieval"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure
            # Ensures to free the resources associated with the statement
            IBM_DB.free_stmt(pstmt) if pstmt
          end
        end
        # The array of record hashes is returned
        results
      end

      # Returns an array of hashes with the column names as keys and
      # column values as values. +sql+ is the select query, 
      # and +name+ is an optional description for logging
      def prepared_select_values(sql_param_hash, name = nil)
        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"}
        results = []
        # Invokes the method +prepare+ in order prepare the SQL
        # IBM_DB.Statement is returned from which the statement is executed and results fetched
        pstmt = prepare(sql_param_hash["sqlSegment"], name)
        if(execute_prepared_stmt(pstmt, sql_param_hash["paramArray"]))
          begin
            results = @servertype.select_rows(sql_param_hash["sqlSegment"], name, pstmt, results)
            if results
              return results.map { |v| v[0] }
            else
              nil
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(pstmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during data retrieval"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure
            # Ensures to free the resources associated with the statement
            IBM_DB.free_stmt(pstmt) if pstmt
          end
        end
        # The array of record hashes is returned
        results
      end

      #Calls the servertype select method to fetch the data
      def fetch_data(stmt)
        if(stmt)
          begin
            return @servertype.select(stmt)
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during data retrieval"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure
          # Ensures to free the resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end
=begin
      # Returns an array of hashes with the column names as keys and
      # column values as values. +sql+ is the select query, 
      # and +name+ is an optional description for logging
      def select(sql, name = nil)
        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"}
        sql.gsub!( /(=\s*NULL|IN\s*\(NULL\))/i, " IS NULL" )
        
        results = []
        # Invokes the method +execute+ in order to log and execute the SQL
        # IBM_DB.Statement is returned from which results can be fetched
        stmt = execute(sql, name)

        results = fetch_data(stmt)
        # The array of record hashes is returned
        results
      end
=end
      def select(sql, name = nil, binds = [])
        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"}
        sql.gsub!( /(=\s*NULL|IN\s*\(NULL\))/i, " IS NULL" )

        results = []

        if(binds.nil? || binds.empty?)
          stmt = execute(sql, name)
        else
          stmt = exec_query(sql, name, binds)
        end

        cols = IBM_DB.resultCols(stmt)

        if( stmt ) 
          results = fetch_data(stmt)
        end

        if(@isAr3)
          return results
        else
          return ActiveRecord::Result.new(cols, results)
        end
      end

      #Returns an array of arrays containing the field values.
      #This is an implementation for the abstract method
      #+sql+ is the select query and +name+ is an optional description for logging
      def select_rows(sql, name = nil,binds = [])
        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"}
        sql.gsub!( /(=\s*NULL|IN\s*\(NULL\))/i, " IS NULL" )
        
        results = []
        # Invokes the method +execute+ in order to log and execute the SQL
        # IBM_DB.Statement is returned from which results can be fetched
        if !binds.nil? && !binds.empty?
          param_array = binds.map do |column,value|
            quote_value_for_pstmt(value, column)
          end
          return prepared_select({"sqlSegment" => sql, "paramArray" => param_array})
        end

        stmt = execute(sql, name)
        if(stmt)
          begin
            results = @servertype.select_rows(sql, name, stmt, results)
          rescue StandardError => fetch_error  # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during data retrieval"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure
            # Ensures to free the resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
        # The array of record hashes is returned
        results
      end

      # Returns a record hash with the column names as keys and column values
      # as values.
      #def select_one(sql, name = nil)
        # Gets the first hash from the array of hashes returned by
        # select_all
      #  select_all(sql,name).first
      #end

      #inserts values from fixtures
      #overridden to handle LOB's fixture insertion, as, in normal inserts callbacks are triggered but during fixture insertion callbacks are not triggered
      #hence only markers like @@@IBMBINARY@@@ will be inserted and are not updated to actual data
      def insert_fixture(fixture, table_name)
        if(fixture.respond_to?(:keys))
          insert_query = "INSERT INTO #{quote_table_name(table_name)} ( #{fixture.keys.join(', ')})"
        else
          insert_query = "INSERT INTO #{quote_table_name(table_name)} ( #{fixture.key_list})"
        end

        insert_values = []
        params = []
        if @servertype.instance_of? IBM_IDS
          super
          return
        end
        column_list = columns(table_name)
        fixture.each do |item|
          col = nil
          column_list.each do |column|
            if column.name.downcase == item.at(0).downcase
              col= column
              break
            end
          end
          if item.at(1).nil? || 
              item.at(1) == {} || 
              (item.at(1) == '' && !(col.type.to_sym == :text))
          
                params << 'NULL'
          
          elsif col.type.to_sym == :xml ||
                 col.type.to_sym == :text ||
                    col.type.to_sym == :binary 
            #  Add a '?' for the parameter or a NULL if the value is nil or empty 
            # (except for a CLOB field where '' can be a value)
             insert_values << quote_value_for_pstmt(item.at(1))
             params << '?'
          else
            insert_values << quote_value_for_pstmt(item.at(1),col)
            params << '?'
          end 
        end
    
        insert_query << " VALUES ("+ params.join(',') + ")"
        unless stmt = IBM_DB.prepare(@connection, insert_query)
           error_msg = IBM_DB.getErrormsg( @connection, IBM_DB::DB_CONN )
           if error_msg && !error_msg.empty?
             raise "Failed to prepare statement for fixtures insert due to : #{error_msg}"
           else
             raise StandardError.new('An unexpected error occurred during preparing SQL for fixture insert')
           end
        end
    
        #log_query(insert_query,'fixture insert')
        log(insert_query,'fixture insert') do
          unless IBM_DB.execute(stmt, insert_values)
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            IBM_DB.free_stmt(stmt) if stmt
            raise "Failed to insert due to: #{error_msg}"
          else
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end

      def empty_insert_statement_value(pkey)
        "(#{pkey}) VALUES (DEFAULT)"
      end

      # Perform an insert and returns the last ID generated.
      # This can be the ID passed to the method or the one auto-generated by the database,
      # and retrieved by the +last_generated_id+ method.
      def insert_direct(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        if @handle_lobs_triggered  #Ensure the array of sql is cleared if they have been handled in the callback
          @sql = []
          @handle_lobs_triggered = false
        end

        clear_query_cache if defined? clear_query_cache

        if stmt = execute(sql, name)
          begin
            @sql << sql
            return id_value || @servertype.last_generated_id(stmt)
            # Ensures to free the resources associated with the statement
          ensure
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end

      def insert(arel, name = nil, pk = nil, id_value = nil, sequence_name = nil, binds = [] )
        sql, binds = [to_sql(arel),binds]

        #unless IBM_DBAdapter.respond_to?(:exec_insert)
        if binds.nil? || binds.empty?
          return insert_direct(sql, name, pk, id_value, sequence_name)
        end

        clear_query_cache if defined? clear_query_cache
        if stmt = exec_insert(sql, name, binds)
          begin
            @sql << sql
            return id_value || @servertype.last_generated_id(stmt)
          ensure
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end

      # Praveen
      # Performs an insert using the prepared statement and returns the last ID generated.
      # This can be the ID passed to the method or the one auto-generated by the database,
      # and retrieved by the +last_generated_id+ method.
      def prepared_insert(pstmt, param_array = nil, id_value = nil)
        if @handle_lobs_triggered  #Ensure the array of sql is cleared if they have been handled in the callback
          @sql                   = []
          @sql_parameter_values  = []
          @handle_lobs_triggered = false
        end

        clear_query_cache if defined? clear_query_cache

        begin
          if execute_prepared_stmt(pstmt, param_array)
            @sql << @prepared_sql
            @sql_parameter_values << param_array
            return id_value || @servertype.last_generated_id(pstmt)
          end
        rescue StandardError => insert_err
          raise insert_err
        ensure
          IBM_DB.free_stmt(pstmt) if pstmt
        end
      end

      # Praveen
      # Prepares and logs +sql+ commands and
      # returns a +IBM_DB.Statement+ object.
      def prepare(sql,name = nil)
        # The +log+ method is defined in the parent class +AbstractAdapter+
        @prepared_sql = sql
        log(sql,name) do
          @servertype.prepare(sql, name)
        end
      end

      # Praveen
      #Executes the prepared statement
      #ReturnsTrue on success and False on Failure
      def execute_prepared_stmt(pstmt, param_array = nil)
        if !param_array.nil? && param_array.size < 1
          param_array = nil
        end

        if( !IBM_DB.execute(pstmt, param_array) )
          error_msg = IBM_DB.getErrormsg(pstmt, IBM_DB::DB_STMT)
          if !error_msg.empty?
            error_msg = "Statement execution failed: " + error_msg
          else
            error_msg = "Statement execution failed"
          end
          IBM_DB.free_stmt(pstmt) if pstmt
          raise StatementInvalid, error_msg
        else
          return true
        end
      end

      # Executes +sql+ statement in the context of this connection using
      # +binds+ as the bind substitutes.  +name+ is logged along with
      # the executed +sql+ statement.
      def exec_query(sql, name = 'SQL', binds = [])
        begin
          param_array = binds.map do |column,value|
            quote_value_for_pstmt(value, column)
          end

          stmt = prepare(sql, name)

           if( stmt )
             if(execute_prepared_stmt(stmt, param_array))
               return stmt
             end
           else
             return false
           end
        ensure
          @offset = @limit = nil
        end
      end

      # Executes and logs +sql+ commands and
      # returns a +IBM_DB.Statement+ object.
      def execute(sql, name = nil)
        # Logs and execute the sql instructions.
        # The +log+ method is defined in the parent class +AbstractAdapter+
        log(sql, name) do
          @servertype.execute(sql, name)
        end
      end

      # Executes an "UPDATE" SQL statement
      def update_direct(sql, name = nil)
        if @handle_lobs_triggered  #Ensure the array of sql is cleared if they have been handled in the callback
          @sql = []
          @handle_lobs_triggered = false
        end

        # Logs and execute the given sql query.
        if stmt = execute(sql, name)
          begin
            @sql << sql
            # Retrieves the number of affected rows
            IBM_DB.num_rows(stmt)
            # Ensures to free the resources associated with the statement
          ensure
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end

      #Praveen
      def prepared_update(pstmt, param_array = nil )
        if @handle_lobs_triggered  #Ensure the array of sql is cleared if they have been handled in the callback
          @sql                   = []
          @sql_parameter_values  = []
          @handle_lobs_triggered = false
        end

        clear_query_cache if defined? clear_query_cache

        begin
          if execute_prepared_stmt(pstmt, param_array)
            @sql << @prepared_sql
            @sql_parameter_values << param_array
            # Retrieves the number of affected rows
            IBM_DB.num_rows(pstmt)
            # Ensures to free the resources associated with the statement
		  end
        rescue StandardError => updt_err
          raise updt_err
        ensure
          IBM_DB.free_stmt(pstmt) if pstmt
        end
      end
      # The delete method executes the delete
      # statement and returns the number of affected rows.
      # The method is an alias for +update+
      alias_method :prepared_delete, :prepared_update

      def update(arel, name = nil, binds = [])
        sql = to_sql(arel)

        # Make sure the WHERE clause handles NULL's correctly
        sqlarray = sql.split(/\s*WHERE\s*/)
        size = sqlarray.size
        if size > 1
          sql = sqlarray[0] + " WHERE "
          if size > 2
            1.upto size-2 do |index|
              sqlarray[index].gsub!( /(=\s*NULL|IN\s*\(NULL\))/i, " IS NULL" ) unless sqlarray[index].nil?
              sql = sql + sqlarray[index] + " WHERE "
            end
          end
          sqlarray[size-1].gsub!( /(=\s*NULL|IN\s*\(NULL\))/i, " IS NULL" ) unless sqlarray[size-1].nil?
          sql = sql + sqlarray[size-1]
        end

        clear_query_cache if defined? clear_query_cache

        if binds.nil? || binds.empty?
          update_direct(sql, name)
        else
          begin
            if stmt = exec_query(sql,name,binds)
              IBM_DB.num_rows(stmt)
            end
          ensure
            IBM_DB.free_stmt(stmt) if(stmt)
          end
        end
      end

      alias_method :delete, :update

      # Begins the transaction (and turns off auto-committing)
      def begin_db_transaction
        # Turns off the auto-commit
        IBM_DB.autocommit(@connection, IBM_DB::SQL_AUTOCOMMIT_OFF)
      end

      # Commits the transaction and turns on auto-committing
      def commit_db_transaction
        # Commits the transaction
        IBM_DB.commit @connection rescue nil
        # Turns on auto-committing
        IBM_DB.autocommit @connection, IBM_DB::SQL_AUTOCOMMIT_ON
      end

      # Rolls back the transaction and turns on auto-committing. Must be
      # done if the transaction block raises an exception or returns false
      def rollback_db_transaction
        # ROLLBACK the transaction
        IBM_DB.rollback(@connection) rescue nil
        # Turns on auto-committing
        IBM_DB.autocommit @connection, IBM_DB::SQL_AUTOCOMMIT_ON
      end


      # Modifies a sql statement in order to implement a LIMIT and an OFFSET.
      # A LIMIT defines the number of rows that should be fetched, while
      # an OFFSET defines from what row the records must be fetched.
      # IBM data servers implement a LIMIT in SQL statements through:
      # FETCH FIRST n ROWS ONLY, where n is the number of rows required.
      # The implementation of OFFSET is more elaborate, and requires the usage of
      # subqueries and the ROW_NUMBER() command in order to add row numbering
      # as an additional column to a copy of the existing table.
      # ==== Examples
      # add_limit_offset!('SELECT * FROM staff', {:limit => 10})
      # generates: "SELECT * FROM staff FETCH FIRST 10 ROWS ONLY"
      #
      # add_limit_offset!('SELECT * FROM staff', {:limit => 10, :offset => 30})
      # generates "SELECT O.* FROM (SELECT I.*, ROW_NUMBER() OVER () sys_rownum
      # FROM (SELECT * FROM staff) AS I) AS O WHERE sys_row_num BETWEEN 31 AND 40"
      def add_limit_offset!(sql, options)
        limit = options[:limit]
        offset = options[:offset]

        # if the limit is zero
        if limit && limit == 0
          # Returns a query that will always generate zero records
          # (e.g. WHERE sys_row_num BETWEEN 1 and 0)
          if( @pstmt_support_on )
            sql = @servertype.query_offset_limit!(sql, 0, limit, options)
          else
            sql = @servertype.query_offset_limit(sql, 0, limit)
          end
        # If there is a non-zero limit
        else
          # If an offset is specified builds the query with offset and limit,
          # otherwise retrieves only the first +limit+ rows
          if( @pstmt_support_on )
            sql = @servertype.query_offset_limit!(sql, offset, limit, options)
          else
            sql = @servertype.query_offset_limit(sql, offset, limit)
          end
        end
        # Returns the sql query in any case
        sql
      end # method add_limit_offset!

      def default_sequence_name(table, column) # :nodoc:
        "#{table}_#{column}_seq"
      end


      #==============================================
      # QUOTING
      #==============================================

      # Quote date/time values for use in SQL input.
      # Includes microseconds, if the value is a Time responding to usec.
      def quoted_date(value) #:nodoc:
        if value.respond_to?(:usec)
          "#{super}.#{sprintf("%06d", value.usec)}"
        else
          super
        end
      end

      def quote_value_for_pstmt(value, column=nil)

        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when String, ActiveSupport::Multibyte::Chars then
            value = value.to_s
            if column && [:integer, :float].include?(column.type)
              value = column.type == :integer ? value.to_i : value.to_f
              value
            else
              value
            end
          when NilClass                 then nil
          when TrueClass                then 1
          when FalseClass               then 0
          when Float, Fixnum, Bignum    then value
          # BigDecimals need to be output in a non-normalized form and quoted.
          when BigDecimal               then value.to_s('F')
          when Numeric, Symbol          then value.to_s
          else
            if value.acts_like?(:date) || value.acts_like?(:time)
              quoted_date(value)
            else
              value.to_yaml
            end
        end
      end

      # Properly quotes the various data types.
      # +value+ contains the data, +column+ is optional and contains info on the field
      def quote(value, column = nil)
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          # If it's a numeric value and the column type is not a string, it shouldn't be quoted
          # (IBM_DB doesn't accept quotes on numeric types)
          when Numeric
            # If the column type is text or string, return the quote value
            if column && column.type.to_sym == :text || column && column.type.to_sym == :string
              unless caller[0] =~ /insert_fixture/i
                  "'#{value}'"
              else
                  "#{value}"
              end 
            else
              # value is Numeric, column.type is not a string,
              # therefore it converts the number to string without quoting it
              value.to_s
            end
          when String, ActiveSupport::Multibyte::Chars
          if column && column.type.to_sym == :binary && !(column.sql_type =~ /for bit data/i)
            # If quoting is required for the insert/update of a BLOB
              unless caller[0] =~ /add_column_options/i
                 # Invokes a convertion from string to binary
                @servertype.set_binary_value
              else
                # Quoting required for the default value of a column
                @servertype.set_binary_default(value)
              end
          elsif column && column.type.to_sym == :text
              unless caller[0] =~ /add_column_options/i
                "'@@@IBMTEXT@@@'"
              else
                @servertype.set_text_default(quote_string(value))
              end
          elsif column && column.type.to_sym == :xml
              unless caller[0] =~ /add_column_options/i
                "'<ibm>@@@IBMXML@@@</ibm>'"
              else
                "#{value}"
              end
          else
              unless caller[0] =~ /insert_fixture/i
                super 
              else
                "#{value}"
              end 
          end
          when TrueClass then quoted_true    # return '1' for true
          when FalseClass then quoted_false  # return '0' for false
          when nil        then "NULL"
          when Date, Time then "'#{quoted_date(value)}'"
          when Symbol     then "'#{quote_string(value.to_s)}'"
          else
            unless caller[0] =~ /insert_fixture/i 
              "'#{quote_string(YAML.dump(value))}'"
            else
              "#{quote_string(YAML.dump(value))}"
            end
        end
      end

      # Quotes a given string, escaping single quote (') characters.
      def quote_string(string)
        string.gsub(/'/, "''")
      end

      # *true* is represented by a smallint 1, *false*
      # by 0, as no native boolean type exists in DB2.
      # Numerics are not quoted in DB2.
      def quoted_true
        "1"
      end

      def quoted_false
        "0"
      end

      def quote_column_name(name)
         @servertype.check_reserved_words(name)
      end

      #==============================================
      # SCHEMA STATEMENTS
      #==============================================

      # Returns a Hash of mappings from the abstract data types to the native
      # database types
      def native_database_types
        {
          :primary_key => { :name => @servertype.primary_key_definition(@start_id)},
          :string      => { :name => "varchar", :limit => 255 },
          :text        => { :name => "clob" },
          :integer     => { :name => "integer" },
          :float       => { :name => "float" },
          :datetime    => { :name => @servertype.get_datetime_mapping },
          :timestamp   => { :name => @servertype.get_datetime_mapping },
          :time        => { :name => @servertype.get_time_mapping },
          :date        => { :name => "date" },
          :binary      => { :name => "blob" },

          # IBM data servers don't have a native boolean type.
          # A boolean can be represented  by a smallint,
          # adopting the convention that False is 0 and True is 1
          :boolean     => { :name => "smallint"},
          :xml         => { :name => "xml"},
          :decimal     => { :name => "decimal" },
          :rowid       => { :name => "rowid" }, # rowid is a supported datatype on z/OS and i/5
          :serial      => { :name => "serial" }, # rowid is a supported datatype on Informix Dynamic Server
          :char        => { :name => "char" },
          :double      => { :name => @servertype.get_double_mapping },
          :decfloat    => { :name => "decfloat"},
          :graphic     => { :name => "graphic", :limit => 1},
          :vargraphic  => { :name => "vargraphic", :limit => 1},
          :bigint      => { :name => "bigint"}
        }
      end

      def build_conn_str_for_dbops()
        connect_str = "DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;"
        if(!@host.nil?)
          connect_str << "HOSTNAME=#{@host};"
          connect_str << "PORT=#{@port};"
          connect_str << "PROTOCOL=TCPIP;"
        end
        connect_str << "UID=#{@username};PWD=#{@password};"
        return connect_str
      end

      def drop_database(dbName)
        connect_str = build_conn_str_for_dbops()

        #Ensure connection is closed before trying to drop a database. 
        #As a connect call would have been made by call seeing connection in active
        disconnect!

        begin
          dropConn = IBM_DB.connect(connect_str, '', '')
        rescue StandardError => connect_err
          raise "Failed to connect to server due to: #{connect_err}"
        end

        if(IBM_DB.dropDB(dropConn,dbName))
          IBM_DB.close(dropConn)
          return true
        else
          error = IBM_DB.getErrormsg(dropConn, IBM_DB::DB_CONN)
          IBM_DB.close(dropConn)
          raise "Could not drop Database due to: #{error}"
        end
      end

      def create_database(dbName, codeSet=nil, mode=nil)
        connect_str = build_conn_str_for_dbops()

        #Ensure connection is closed before trying to drop a database.
        #As a connect call would have been made by call seeing connection in active
        disconnect!

        begin
          createConn = IBM_DB.connect(connect_str, '', '')
        rescue StandardError => connect_err
          raise "Failed to connect to server due to: #{connect_err}"
        end

        if(IBM_DB.createDB(createConn,dbName,codeSet,mode))
          IBM_DB.close(createConn)
          return true
        else
          error = IBM_DB.getErrormsg(createConn, IBM_DB::DB_CONN)
          IBM_DB.close(createConn)
          raise "Could not create Database due to: #{error}"
        end
      end

      # IBM data servers do not support limits on certain data types (unlike MySQL)
      # Limit is supported for the {float, decimal, numeric, varchar, clob, blob, graphic, vargraphic} data types.
      def type_to_sql(type, limit = nil, precision = nil, scale = nil)
        if type.to_sym == :decfloat
          sql_segment = native_database_types[type.to_sym][:name].to_s
          sql_segment << "(#{precision})" if !precision.nil?
          return sql_segment
        end
        
        return super if limit.nil?

        # strip off limits on data types not supporting them
        if @servertype.limit_not_supported_types.include? type.to_sym
          return native_database_types[type.to_sym][:name].to_s
        elsif type.to_sym == :boolean
          return "smallint"
        else
          return super
        end
      end 

      # Returns the maximum length a table alias identifier can be.
      # IBM data servers (cross-platform) table limit is 128 characters
      def table_alias_length
        128
      end

      # Retrieves table's metadata for a specified shema name
      def tables(name = nil)
        # Initializes the tables array
        tables = []
        # Retrieve table's metadata through IBM_DB driver
        stmt = IBM_DB.tables(@connection, nil, 
                            @servertype.set_case(@schema))
        if(stmt)
          begin
            # Fetches all the records available
            while tab = IBM_DB.fetch_assoc(stmt)
              # Adds the lowercase table name to the array
              if(tab["table_type"]== 'TABLE')  #check, so that only tables are dumped,IBM_DB.tables also returns views,alias etc in the schema
                tables << tab["table_name"].downcase    
              end
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve table metadata during fetch: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of table metadata"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure
            IBM_DB.free_stmt(stmt)  if stmt # Free resources associated with the statement
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve tables metadata due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during retrieval of table metadata')
          end
        end
        # Returns the tables array
        return tables
      end

      # Returns the primary key of the mentioned table
      def primary_key(table_name)
        pk_name = nil
        stmt = IBM_DB.primary_keys( @connection, nil, 
                                    @servertype.set_case(@schema), 
                                    @servertype.set_case(table_name))
        if(stmt) 
          begin
            if ( pk_index_row = IBM_DB.fetch_array(stmt) )
              pk_name = pk_index_row[3].downcase
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg( stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve primarykey metadata during fetch: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of primary key metadata"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure  # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else
          error_msg = IBM_DB.getErrormsg( @connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve primary key metadata due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during primary key retrieval')
          end
        end
        return pk_name
      end

      # Returns an array of non-primary key indexes for a specified table name
      def indexes(table_name, name = nil)
                # to_s required because +table_name+ may be a symbol.
        table_name = table_name.to_s
        # Checks if a blank table name has been given.
        # If so it returns an empty array of columns.
        return [] if table_name.strip.empty?

        indexes = []
        pk_index = nil
        index_schema = []
        
        #fetch the primary keys of the table using function primary_keys
        #TABLE_SCHEM:: pk_index[1]
        #TABLE_NAME:: pk_index[2]
        #COLUMN_NAME:: pk_index[3]
        #PK_NAME:: pk_index[5]
        stmt = IBM_DB.primary_keys( @connection, nil, 
                                   @servertype.set_case(@schema), 
                                   @servertype.set_case(table_name))
        if(stmt)
          begin
            while ( pk_index_row = IBM_DB.fetch_array(stmt) )
              if pk_index_row[5] 
                pk_index_name = pk_index_row[5].downcase
                pk_index_columns = [pk_index_row[3].downcase]           # COLUMN_NAME
                if pk_index 
                  pk_index.columns = pk_index.columns + pk_index_columns
                else
                  pk_index = IndexDefinition.new(table_name, pk_index_name, true, pk_index_columns)
                end
              end 
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve primarykey metadata during fetch: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of primary key metadata"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure  # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else  # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve primary key metadata due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during primary key retrieval')
          end
        end

        # Query table statistics for all indexes on the table
        # "TABLE_NAME:   #{index_stats[2]}"
        # "NON_UNIQUE:   #{index_stats[3]}"
        # "INDEX_NAME:   #{index_stats[5]}"
        # "COLUMN_NAME:  #{index_stats[8]}"
        stmt = IBM_DB.statistics( @connection, nil, 
                                  @servertype.set_case(@schema), 
                                  @servertype.set_case(table_name), 1 )
        if(stmt)
          begin
            while ( index_stats = IBM_DB.fetch_array(stmt) )
                is_composite = false
              if index_stats[5]             # INDEX_NAME
                index_name = index_stats[5].downcase
                index_unique = (index_stats[3] == 0)
                index_columns = [index_stats[8].downcase]     # COLUMN_NAME
                index_qualifier = index_stats[4].downcase             #Index_Qualifier
                # Create an IndexDefinition object and add to the indexes array
                i = 0;
                indexes.each do |index|
                  if index.name == index_name && index_schema[i] == index_qualifier
                     index.columns = index.columns + index_columns
                     is_composite = true
                  end 
                  i = i+1
                end
              
                unless is_composite 
                  indexes << IndexDefinition.new(table_name, index_name, index_unique, index_columns)
                  index_schema << index_qualifier
                end 
              end
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve index metadata during fetch: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of index metadata"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure  # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else  # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve index metadata due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during index retrieval')
          end
        end
    
        # remove the primary key index entry.... should not be dumped by the dumper
    
        i = 0
        indexes.each do |index|
          if pk_index && index.columns == pk_index.columns
            indexes.delete_at(i)
          end
          i = i+1
        end 
        # Returns the indexes array
        return indexes
      end

      # Returns an array of Column objects for the table specified by +table_name+
      def columns(table_name, name = nil)
        # to_s required because it may be a symbol.
        table_name = @servertype.set_case(table_name.to_s)
        # Checks if a blank table name has been given.
        # If so it returns an empty array
        return [] if table_name.strip.empty?
        # +columns+ will contain the resulting array
        columns = []
        # Statement required to access all the columns information
        stmt = IBM_DB.columns( @connection, nil, 
                                   @servertype.set_case(@schema), 
                                   @servertype.set_case(table_name) )
        if(stmt)
          begin
            # Fetches all the columns and assigns them to col.
            # +col+ is an hash with keys/value pairs for a column
            while col = IBM_DB.fetch_assoc(stmt)
              column_name = col["column_name"].downcase
              # Assigns the column default value.
              column_default_value = col["column_def"]
              # If there is no default value, it assigns NIL
              column_default_value = nil if (column_default_value && column_default_value.upcase == 'NULL')
              # If default value is IDENTITY GENERATED BY DEFAULT (this value is retrieved in case of id columns)
              column_default_value = nil if (column_default_value && column_default_value.upcase =~ /IDENTITY GENERATED BY DEFAULT/i)
              # Removes single quotes from the default value
              column_default_value.gsub!(/^'(.*)'$/, '\1') unless column_default_value.nil?
              # Assigns the column type
              column_type = col["type_name"].downcase
              # Assigns the field length (size) for the column
              column_length = col["column_size"]
              column_scale = col["decimal_digits"]
              # The initializer of the class Column, requires the +column_length+ to be declared 
              # between brackets after the datatype(e.g VARCHAR(50)) for :string and :text types. 
              # If it's a "for bit data" field it does a subsitution in place, if not
              # it appends the (column_length) string on the supported data types
              unless column_length.nil? || 
                     column_length == '' || 
                     column_type.sub!(/ \(\) for bit data/i,"(#{column_length}) FOR BIT DATA") || 
                     !column_type =~ /char|lob|graphic/i
                if column_type =~ /decimal/i
                  column_type << "(#{column_length},#{column_scale})"
                elsif column_type =~ /smallint|integer|double|date|time|timestamp|xml|bigint/i
                  column_type << ""  # override native limits incompatible with table create
                else
                  column_type << "(#{column_length})"
                end
              end
              # col["NULLABLE"] is 1 if the field is nullable, 0 if not.
              column_nullable = (col["nullable"] == 1) ? true : false
              # Make sure the hidden column (db2_generated_rowid_for_lobs) in DB2 z/OS isn't added to the list
              if !(column_name =~ /db2_generated_rowid_for_lobs/i)
                # Pushes into the array the *IBM_DBColumn* object, created by passing to the initializer
                # +column_name+, +default_value+, +column_type+ and +column_nullable+.
                columns << IBM_DBColumn.new(column_name, column_default_value, column_type, column_nullable)
              end
            end
          rescue StandardError => fetch_error # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve column metadata during fetch: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of column metadata"
              error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
              raise error_msg
            end
          ensure  # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else  # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve column metadata due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during retrieval of columns metadata')
          end
        end
        # Returns the columns array
        return columns
      end

      # Renames a table.
      # ==== Example
      # rename_table('octopuses', 'octopi')
      # Overriden to satisfy IBM data servers syntax
      def rename_table(name, new_name)
        # SQL rename table statement
        rename_table_sql = "RENAME TABLE #{name} TO #{new_name}"
        stmt = execute(rename_table_sql)
        # Ensures to free the resources associated with the statement
        ensure
          IBM_DB.free_stmt(stmt) if stmt
      end

      # Renames a column.
      # ===== Example
      #  rename_column(:suppliers, :description, :name)
      def rename_column(table_name, column_name, new_column_name)
        @servertype.rename_column(table_name, column_name, new_column_name)
      end

      # Removes the column from the table definition.
      # ===== Examples
      #  remove_column(:suppliers, :qualification)
      def remove_column(table_name, column_name)
        @servertype.remove_column(table_name, column_name)
      end

      # Changes the column's definition according to the new options.
      # See TableDefinition#column for details of the options you can use.
      # ===== Examples
      #  change_column(:suppliers, :name, :string, :limit => 80)
      #  change_column(:accounts, :description, :text)
      def change_column(table_name, column_name, type, options = {})
        @servertype.change_column(table_name, column_name, type, options)
      end

=begin
      #overrides the abstract adapter method to generate proper sql
      #specifying the column options, like default value and nullability clause
      def add_column_options!(sql,options={})
        #add default null option only if :default option is not specified and 
        #:null option is not specified or is true
        if (options[:default].nil? && (options[:null].nil? || options[:null] == true))
          sql << " DEFAULT NULL"
        else  
          if( !options[:default].nil?)
              #check, :column option is passed only in case of create_table but not in case of add_column
            if (!options[:column].nil?)   
              sql << " DEFAULT #{quote(options[:default],options[:column])}"
            else
              sql << " DEFAULT #{quote(options[:default])}" 
            end 
          end 
          #append NOT NULL to sql only---
          #---if options[:null] is not nil and is equal to false
          unless options[:null] == nil 
             sql << " NOT NULL" if (options[:null] == false)
          end
        end   
      end
=end

      #Add distinct clause to the sql if there is no order by specified
      def distinct(columns, order_by)
        if order_by.nil?
          "DISTINCT #{columns}"
        else
          "#{columns}"
        end
      end

      # Sets a new default value for a column. This does not set the default
      # value to +NULL+, instead, it needs DatabaseStatements#execute which
      # can execute the appropriate SQL statement for setting the value.
      # ==== Examples
      #  change_column_default(:suppliers, :qualification, 'new')
      #  change_column_default(:accounts, :authorized, 1)
      # Method overriden to satisfy IBM data servers syntax.
      def change_column_default(table_name, column_name, default)
        @servertype.change_column_default(table_name, column_name, default)
      end

      #Changes the nullability value of a column
      def change_column_null(table_name, column_name, null, default = nil)
        @servertype.change_column_null(table_name, column_name, null, default)
      end

      # Remove the given index from the table.
      #
      # Remove the suppliers_name_index in the suppliers table (legacy support, use the second or third forms).
      #   remove_index :suppliers, :name
      # Remove the index named accounts_branch_id in the accounts table.
      #   remove_index :accounts, :column => :branch_id
      # Remove the index named by_branch_party in the accounts table.
      #   remove_index :accounts, :name => :by_branch_party
      #
      # You can remove an index on multiple columns by specifying the first column.
      #   add_index :accounts, [:username, :password]
      #   remove_index :accounts, :username
      # Overriden to use the IBM data servers SQL syntax.
      def remove_index(table_name, options = {})
        execute("DROP INDEX #{index_name(table_name, options)}")
      end
    end # class IBM_DBAdapter

    # This class contains common code across DB's (DB2 LUW, zOS, i5 and IDS)
    class IBM_DataServer
      def initialize(adapter, ar3)
        @adapter = adapter
		@isAr3 = ar3
      end

      def last_generated_id(stmt)
      end

      def create_index_after_table (table_name,cloumn_name)
      end

      def setup_for_lob_table ()
      end

      def reorg_table(table_name)
      end

      def check_reserved_words(col_name)
        col_name.to_s
      end

      # This is supported by the DB2 for Linux, UNIX, Windows data servers
      # and by the DB2 for i5 data servers
      def remove_column(table_name, column_name)
        begin
          @adapter.execute "ALTER TABLE #{table_name} DROP #{column_name}"
          reorg_table(table_name)
        rescue StandardError => exec_err
          # Provide details on the current XML columns support
          if exec_err.message.include?('SQLCODE=-1242') && exec_err.message.include?('42997')
            raise StatementInvalid, 
                  "A column that is part of a table containing an XML column cannot be dropped. \
To remove the column, the table must be dropped and recreated without the #{column_name} column: #{exec_err}"
          else
            raise "#{exec_err}"
          end
        end
      end

      def select(stmt)
        results = []
        # Fetches all the results available. IBM_DB.fetch_assoc(stmt) returns
        # an hash for each single record.
        # The loop stops when there aren't any more valid records to fetch
        begin
        if(@isAr3)
            while single_hash = IBM_DB.fetch_assoc(stmt)
              # Add the record to the +results+ array
              results <<  single_hash
            end
          else
            while single_hash = IBM_DB.fetch_array(stmt)
              # Add the record to the +results+ array
              results <<  single_hash
            end
          end
        rescue StandardError => fetch_error # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
          if error_msg && !error_msg.empty?
            raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
          else
            error_msg = "An unexpected error occurred during data retrieval"
            error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
            raise error_msg
          end
        end
        return results
      end

      def select_rows(sql, name, stmt, results)
        # Fetches all the results available. IBM_DB.fetch_array(stmt) returns
        # an array representing a row in a result set.
        # The loop stops when there aren't any more valid records to fetch
        begin
          while single_array = IBM_DB.fetch_array(stmt)
            #Add the array to results array
            results <<  single_array
          end
        rescue StandardError => fetch_error # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
          if error_msg && !error_msg.empty?
            raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
          else
            error_msg = "An unexpected error occurred during data retrieval"
            error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
            raise error_msg
          end
        end
        return results
      end

      # Praveen
      def prepare(sql,name = nil)
        begin
          stmt = IBM_DB.prepare(@adapter.connection, sql)
          if( stmt )
            stmt
          else
            raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
          end
        rescue StandardError => prep_err
          if prep_err && !prep_err.message.empty?
            raise "Failed to prepare sql #{sql} due to: #{prep_err}"
          else 
            raise
          end
        end
      end

      def execute(sql, name = nil)
        begin
          if stmt = IBM_DB.exec(@adapter.connection, sql)
            stmt   # Return the statement object
          else
            raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
          end
        rescue StandardError => exec_err
          if exec_err && !exec_err.message.empty?
            raise "Failed to execute statement due to: #{exec_err}"
          else 
            raise
          end
        end
      end

      def set_schema(schema)
        @adapter.execute("SET SCHEMA #{schema}")
      end

      def query_offset_limit(sql, offset, limit)
      end

      def query_offset_limit!(sql, offset, limit, options)
      end
      
      def get_datetime_mapping
      end

      def get_time_mapping
      end

      def get_double_mapping
      end
    
      def change_column_default(table_name, column_name, default)
      end

      def change_column_null(table_name, column_name, null, default)
      end
  
      def set_binary_default(value)
      end

      def set_binary_value
      end

      def set_text_default
      end

      def set_case(value)
      end

      def limit_not_supported_types
        [:integer, :double, :date, :time, :timestamp, :xml, :bigint]
      end
    end # class IBM_DataServer

    class IBM_DB2 < IBM_DataServer
      def initialize(adapter, ar3)
        super(adapter,ar3)
        @limit = @offset = nil
      end

      def rename_column(table_name, column_name, new_column_name)
        raise NotImplementedError, "rename_column is not implemented yet in the IBM_DB Adapter"
      end

      def primary_key_definition(start_id)
        return "INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH #{start_id}) PRIMARY KEY"
      end

      # Returns the last automatically generated ID.
      # This method is required by the +insert+ method
      # The "stmt" parameter is ignored for DB2 but used for IDS
      def last_generated_id(stmt)
        # Queries the db to obtain the last ID that was automatically generated
        sql = "SELECT IDENTITY_VAL_LOCAL() FROM SYSIBM.SYSDUMMY1"
        stmt = IBM_DB.prepare(@adapter.connection, sql)
        if(stmt)
          if(IBM_DB.execute(stmt, nil))
            begin
              # Fetches the only record available (containing the last id)
              IBM_DB.fetch_row(stmt)
              # Retrieves and returns the result of the query with the last id.
              IBM_DB.result(stmt,0)
            rescue StandardError => fetch_error # Handle driver fetch errors
              error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
              if error_msg && !error_msg.empty?
                raise "Failed to retrieve last generated id: #{error_msg}"
              else
                error_msg = "An unexpected error occurred during retrieval of last generated id"
                error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
                raise error_msg
              end
            ensure  # Free resources associated with the statement
              IBM_DB.free_stmt(stmt) if stmt
            end
          else
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
            IBM_DB.free_stmt(stmt) if stmt
            if error_msg && !error_msg.empty?
              raise "Failed to retrieve last generated id: #{error_msg}"
            else
              error_msg = "An unexpected error occurred during retrieval of last generated id"
              raise error_msg
            end
          end
        else
          error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
          if error_msg && !error_msg.empty?
            raise "Failed to retrieve last generated id due to error: #{error_msg}"
          else
            raise StandardError.new('An unexpected error occurred during retrieval of last generated id')
          end
        end
      end

      def change_column(table_name, column_name, type, options)
        data_type = @adapter.type_to_sql(type, options[:limit], options[:precision], options[:scale])
        begin
          execute "ALTER TABLE #{table_name} ALTER #{column_name} SET DATA TYPE #{data_type}"
        rescue StandardError => exec_err
          if exec_err.message.include?('SQLCODE=-190')
            raise StatementInvalid, 
            "Please consult documentation for compatible data types while changing column datatype. \
The column datatype change to [#{data_type}] is not supported by this data server: #{exec_err}"
          else
            raise "#{exec_err}"
          end
        end
        reorg_table(table_name)
        change_column_null(table_name,column_name,options[:null],nil)
        change_column_default(table_name, column_name, options[:default])
        reorg_table(table_name)
      end

      # DB2 specific ALTER TABLE statement to add a default clause
      def change_column_default(table_name, column_name, default)
        # SQL statement which alters column's default value
        change_column_sql = "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} \
SET WITH DEFAULT #{@adapter.quote(default)}"

        stmt = execute(change_column_sql)
        reorg_table(table_name)
        ensure
          IBM_DB.free_stmt(stmt) if stmt
      end

      #DB2 specific ALTER TABLE statement to change the nullability of a column
      def change_column_null(table_name, column_name, null, default)
        if !default.nil?
          change_column_default(table_name, column_name, default)
        end 

        if !null.nil? 
          if null
            change_column_sql = "ALTER TABLE #{table_name} ALTER #{column_name} DROP NOT NULL"
          else
            change_column_sql = "ALTER TABLE #{table_name} ALTER #{column_name} SET NOT NULL"
          end
          stmt = execute(change_column_sql)
          reorg_table(table_name)
        end

        ensure
          IBM_DB.free_stmt(stmt) if stmt   
      end
    
      # This method returns the DB2 SQL type corresponding to the Rails
      # datetime/timestamp type
      def get_datetime_mapping
        return "timestamp"
      end

      # This method returns the DB2 SQL type corresponding to the Rails
      # time type
      def get_time_mapping
        return "time"
      end

      #This method returns the DB2 SQL type corresponding to Rails double type
      def get_double_mapping
        return "double"
      end
=begin
      # Commenting this code, as offset handling is now part of sql and we need to handle it in select and also
      # need not set cursor type during prepare or execute
      # Fetches all the results available. IBM_DB.fetch_assoc(stmt) returns
      # an hash for each single record.
      # The loop stops when there aren't any more valid records to fetch
      def select(stmt)
        results = []
        begin
          if (!@offset.nil? && @offset >= 0) || (!@limit.nil? && @limit > 0)
            # We know at this point that there is an offset and/or a limit
            # Check if the cursor type is set correctly
            cursor_type = IBM_DB.get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
            @offset = 0 if @offset.nil?
            if (cursor_type == IBM_DB::SQL_CURSOR_STATIC)
              index = 0
              # Get @limit rows starting at @offset
              while (index < @limit)
                # We increment the offset by 1 because for DB2 the offset of the initial row is 1 instead of 0
                if single_hash = IBM_DB.fetch_assoc(stmt, @offset + index + 1)
                  # Add the record to the +results+ array
                  results <<  single_hash
                  index = index + 1
                else
                  # break from the while loop
                  break 
                end
              end
            else # cursor != IBM_DB::SQL_CURSOR_STATIC
              # If the result set contains a LOB, the cursor type will never be SQL_CURSOR_STATIC
              # because DB2 does not allow this. We can't use the offset mechanism because the cursor 
              # is not scrollable. In this case, ignore first @offset rows and return rows starting 
              # at @offset to @offset + @limit
              index = 0
              while (index < @offset + @limit)
                if single_hash = IBM_DB.fetch_assoc(stmt)
                  # Add the record to the +results+ array only from row @offset to @offset + @limit
                  if (index >= @offset)
                    results <<  single_hash
                  end
                  index = index + 1
                else
                  # break from the while loop
                  break
                end
              end
            end
          # This is the case where limit is set to zero
          # Simply return an empty +results+
          elsif (!@limit.nil? && @limit == 0)
            results
          # No limits or offsets specified
          else
            while single_hash = IBM_DB.fetch_assoc(stmt)
              # Add the record to the +results+ array
              results <<  single_hash
            end
            return results
          end
        rescue StandardError => fetch_error # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
          if error_msg && !error_msg.empty?
            raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
          else
            error_msg = "An unexpected error occurred during data retrieval"
            error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
            raise error_msg
          end
        ensure
          # Assign the instance variables to nil. We will not be using them again
          @offset = nil
          @limit = nil
        end
      end

      # Fetches all the results available. IBM_DB.fetch_array(stmt) returns
      # an array for each single record.
      # The loop stops when there aren't any more valid records to fetch
      def select_rows(sql, name, stmt, results)
        begin
          if (!@offset.nil? && @offset >= 0) || (!@limit.nil? && @limit > 0)
            # We know at this point that there is an offset and/or a limit
            # Check if the cursor type is set correctly
            cursor_type = IBM_DB.get_option stmt, IBM_DB::SQL_ATTR_CURSOR_TYPE, 0
            @offset = 0 if @offset.nil?
            if (cursor_type == IBM_DB::SQL_CURSOR_STATIC)
              index = 0
              # Get @limit rows starting at @offset
              while (index < @limit)
                # We increment the offset by 1 because for DB2 the offset of the initial row is 1 instead of 0
                if single_array = IBM_DB.fetch_array(stmt, @offset + index + 1)
                  # Add the array to the +results+ array
                  results <<  single_array
                  index = index + 1
                else
                  # break from the while loop
                  break 
                end
              end
            else # cursor != IBM_DB::SQL_CURSOR_STATIC
              # If the result set contains a LOB, the cursor type will never be SQL_CURSOR_STATIC
              # because DB2 does not allow this. We can't use the offset mechanism because the cursor 
              # is not scrollable. In this case, ignore first @offset rows and return rows starting 
              # at @offset to @offset + @limit
              index = 0
              while (index < @offset + @limit)
                if single_array = IBM_DB.fetch_array(stmt)
                  # Add the array to the +results+ array only from row @offset to @offset + @limit
                  if (index >= @offset)
                    results <<  single_array
                  end
                  index = index + 1
                else
                  # break from the while loop
                  break
                end
              end
            end
          # This is the case where limit is set to zero
          # Simply return an empty +results+
          elsif (!@limit.nil? && @limit == 0)
            results
          # No limits or offsets specified
          else
            while single_array = IBM_DB.fetch_array(stmt)
              # Add the array to the +results+ array
              results <<  single_array
            end
          end
        rescue StandardError => fetch_error # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT )
          if error_msg && !error_msg.empty?
            raise StatementInvalid,"Failed to retrieve data: #{error_msg}"
          else
            error_msg = "An unexpected error occurred during data retrieval"
            error_msg = error_msg + ": #{fetch_error.message}" if !fetch_error.message.empty?
            raise error_msg
          end
        ensure
          # Assign the instance variables to nil. We will not be using them again
          @offset = nil
          @limit = nil
        end
        return results
      end

      # Praveen
      def prepare(sql,name = nil)
        # Check if there is a limit and/or an offset
        # If so then make sure and use a static cursor type
        begin
          if (!@offset.nil? && @offset >= 0) || (!@limit.nil? && @limit > 0)
            # Set the cursor type to static so we can later utilize the offset and limit correctly
            if stmt = IBM_DB.prepare(@adapter.connection, sql, 
                      {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_STATIC})
              stmt   # Return the statement object
            else
              raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            end
          else
            if stmt = IBM_DB.prepare(@adapter.connection, sql)
              stmt   # Return the statement object
            else
              raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            end
          end
        rescue StandardError => prep_err
          error_msg = "Failed to prepare sql #{sql}"
          error_msg = error_msg + ": #{prep_err.message}" if !prep_err.message.empty?     
          raise error_msg
        end
      end

      # Praveen
      def execute(sql, name = nil)
        # Check if there is a limit and/or an offset
        # If so then make sure and use a static cursor type
        begin
          if (!@offset.nil? && @offset >= 0) || (!@limit.nil? && @limit > 0)
            # Set the cursor type to static so we can later utilize the offset and limit correctly
            if stmt = IBM_DB.exec(@adapter.connection, sql, 
                      {IBM_DB::SQL_ATTR_CURSOR_TYPE => IBM_DB::SQL_CURSOR_STATIC})
              stmt   # Return the statement object
            else
              raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            end
          else
            if stmt = IBM_DB.exec(@adapter.connection, sql)
              stmt   # Return the statement object
            else
              raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            end
          end
        rescue StandardError => exec_err
          error_msg = "Failed to execute statement"
          error_msg = error_msg + ": #{exec_err.message}" if !exec_err.message.empty?     
          raise error_msg
        end
      end
=end
      def query_offset_limit(sql, offset, limit)
        if(offset.nil? && limit.nil?)
          return sql
        end

        if (offset.nil?)
           return sql << " FETCH FIRST #{limit} ROWS ONLY"
        end

        if(limit.nil?)
          sql.sub!(/SELECT/i,"SELECT O.* FROM (SELECT I.*, ROW_NUMBER() OVER () sys_row_num FROM (SELECT")
          return sql << ") AS I) AS O WHERE sys_row_num > #{offset}"
        end

        # Defines what will be the last record
        last_record = offset + limit
        # Transforms the SELECT query in order to retrieve/fetch only
        # a number of records after the specified offset.
        # 'select' or 'SELECT' is replaced with the partial query below that adds the sys_row_num column
        # to select with the condition of this column being between offset+1 and the offset+limit
        sql.sub!(/SELECT/i,"SELECT O.* FROM (SELECT I.*, ROW_NUMBER() OVER () sys_row_num FROM (SELECT")
        # The final part of the query is appended to include a WHERE...BETWEEN...AND condition,
        # and retrieve only a LIMIT number of records starting from the OFFSET+1
        sql << ") AS I) AS O WHERE sys_row_num BETWEEN #{offset+1} AND #{last_record}"
      end

      def query_offset_limit!(sql, offset, limit, options)
        if(offset.nil? && limit.nil?)
          options[:paramArray] = []
          return sql
        end

        if (offset.nil?)
           options[:paramArray] = []
           return sql << " FETCH FIRST #{limit} ROWS ONLY"
        end
    
        if(limit.nil?)
          sql.sub!(/SELECT/i,"SELECT O.* FROM (SELECT I.*, ROW_NUMBER() OVER () sys_row_num FROM (SELECT")
          sql << ") AS I) AS O WHERE sys_row_num > ?"
          options[:paramArray] = [offset]
          return 
        end

        # Defines what will be the last record
        last_record = offset + limit
        # Transforms the SELECT query in order to retrieve/fetch only
        # a number of records after the specified offset.
        # 'select' or 'SELECT' is replaced with the partial query below that adds the sys_row_num column
        # to select with the condition of this column being between offset+1 and the offset+limit
        sql.sub!(/SELECT/i,"SELECT O.* FROM (SELECT I.*, ROW_NUMBER() OVER () sys_row_num FROM (SELECT")
        # The final part of the query is appended to include a WHERE...BETWEEN...AND condition,
        # and retrieve only a LIMIT number of records starting from the OFFSET+1
        sql << ") AS I) AS O WHERE sys_row_num BETWEEN ? AND ?"
        options[:paramArray] = [offset+1, last_record]
      end

      # This method generates the default blob value specified for 
      # DB2 Dataservers
      def set_binary_default(value)
        "BLOB('#{value}')"
      end

      # This method generates the blob value specified for DB2 Dataservers
      def set_binary_value
        "BLOB('?')"       
      end

      # This method generates the default clob value specified for 
      # DB2 Dataservers
      def set_text_default(value)
        "'#{value}'"
      end

      # For DB2 Dataservers , the arguments to the meta-data functions
      # need to be in upper-case
      def set_case(value)
        value.upcase
      end
    end # class IBM_DB2

    class IBM_DB2_LUW < IBM_DB2
      # Reorganizes the table for column changes
      def reorg_table(table_name)
        execute("CALL ADMIN_CMD('REORG TABLE #{table_name}')")
      end
    end # class IBM_DB2_LUW

    class IBM_DB2_LUW_COBRA < IBM_DB2_LUW
      # Cobra supports parameterised timestamp, 
      # hence overriding following method to allow timestamp datatype to be parameterised
      def limit_not_supported_types
        [:integer, :double, :date, :time, :xml, :bigint]
      end

      # Alter table column for renaming a column
      # This feature is supported for against DB2 V97 and above only
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        empty_condition  = _table_name.empty? || 
                             _column_name.empty? || 
                               _new_column_name.empty? unless nil_condition

        if nil_condition || empty_condition
          raise ArgumentError,"One of the arguments passed to rename_column is empty or nil"
        end

        begin
          rename_column_sql = "ALTER TABLE #{_table_name} RENAME COLUMN #{_column_name} \
                   TO #{_new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            if error_msg && !error_msg.empty?
              raise "Rename column failed : #{error_msg}"
            else
              raise StandardError.new('An unexpected error occurred during renaming the column')
            end
          end

          reorg_table(_table_name)

        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end #End of begin
      end # End of rename_column
    end #IBM_DB2_LUW_COBRA

    module HostedDataServer
      require 'pathname'
      #find DB2-i5-zOS rezerved words file relative path
      rfile = Pathname.new(File.dirname(__FILE__)).parent + 'vendor' + 'db2-i5-zOS.yaml'
      if rfile
        RESERVED_WORDS = open(rfile.to_s) {|f| YAML.load(f) }
        def check_reserved_words(col_name)
          if RESERVED_WORDS[col_name]
            '"' + RESERVED_WORDS[col_name] + '"'
          else
            col_name.to_s
          end
        end
      else
        raise "Failed to locate IBM_DB Adapter dependency: #{rfile}"
      end
    end # module HostedDataServer

    class IBM_DB2_ZOS < IBM_DB2
      # since v9 doesn't need, suggest putting it in HostedDataServer?      
      def create_index_after_table(table_name,column_name)
        @adapter.add_index(table_name, column_name, :unique => true) 
      end

      def remove_column(table_name, column_name)
        raise NotImplementedError,
        "remove_column is not supported by the DB2 for zOS data server"
      end  

      #Alter table column for renaming a column
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        empty_condition  = _table_name.empty? || 
                             _column_name.empty? || 
                               _new_column_name.empty? unless nil_condition

        if nil_condition || empty_condition
          raise ArgumentError,"One of the arguments passed to rename_column is empty or nil"
        end

        begin
          rename_column_sql = "ALTER TABLE #{_table_name} RENAME COLUMN #{_column_name} \
                   TO #{_new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            if error_msg && !error_msg.empty?
              raise "Rename column failed : #{error_msg}"
            else
              raise StandardError.new('An unexpected error occurred during renaming the column')
            end
          end

          reorg_table(_table_name)

        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end #End of begin
      end # End of rename_column

      # DB2 z/OS only allows NULL or "" (empty) string as DEFAULT value for a BLOB column. 
      # For non-empty string and non-NULL values, the server returns error
      def set_binary_default(value)
        "#{value}"
      end

      def change_column_default(table_name, column_name, default)
        unless default
          raise NotImplementedError,
          "DB2 for zOS data server version 9 does not support changing the column default to NULL"
        else
          super
        end
      end

      def change_column_null(table_name, column_name, null, default)
        raise NotImplementedError,
        "DB2 for zOS data server does not support changing the column's nullability"
      end
    end # class IBM_DB2_ZOS

    class IBM_DB2_ZOS_8 < IBM_DB2_ZOS
      include HostedDataServer

      def query_offset_limit(sql, offset, limit)
        if (!limit.nil?)
           sql << " FETCH FIRST #{limit} ROWS ONLY"
        end
        return sql
      end

      def query_offset_limit!(sql, offset, limit, options)
        if (!limit.nil?)
           sql << " FETCH FIRST #{limit} ROWS ONLY"
        end
        options[:paramArray] = []
      end

      # This call is needed on DB2 z/OS v8 for the creation of tables
      # with LOBs.  When issued, this call does the following:
      #   DB2 creates LOB table spaces, auxiliary tables, and indexes on auxiliary
      #   tables for LOB columns.
      def setup_for_lob_table()
        execute "SET CURRENT RULES = 'STD'"
      end

      def rename_column(table_name, column_name, new_column_name)
        raise NotImplementedError, "rename_column is not implemented for DB2 on zOS 8"
      end

      def change_column_default(table_name, column_name, default)
        raise NotImplementedError,
        "DB2 for zOS data server version 8 does not support changing the column default"
      end
     
    end # class IBM_DB2_ZOS_8
    
    class IBM_DB2_I5 < IBM_DB2
      include HostedDataServer
    end # class IBM_DB2_I5

    class IBM_IDS < IBM_DataServer
      # IDS does not support the SET SCHEMA syntax
      def set_schema(schema)
      end

      # IDS specific ALTER TABLE statement to rename a column
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        empty_condition  = _table_name.empty? || 
                             _column_name.empty? || 
                               _new_column_name.empty? unless nil_condition

        if nil_condition || empty_condition
          raise ArgumentError,"One of the arguments passed to rename_column is empty or nil"
        end

        begin
          rename_column_sql = "RENAME COLUMN #{table_name}.#{column_name} TO \
               #{new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN )
            if error_msg && !error_msg.empty?
              raise "Rename column failed : #{error_msg}"
            else
              raise StandardError.new('An unexpected error occurred during renaming the column')
            end
          end

          reorg_table(_table_name)

        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end #End of begin
      end # End of rename_column

      def primary_key_definition(start_id)
        return "SERIAL(#{start_id}) PRIMARY KEY"
      end

      def change_column(table_name, column_name, type, options)
        if !options[:null].nil? && !options[:null]
          execute "ALTER TABLE #{table_name} MODIFY #{column_name} #{@adapter.type_to_sql(type, options[:limit], options[:precision], options[:scale])} NOT NULL"
        else
          execute "ALTER TABLE #{table_name} MODIFY #{column_name} #{@adapter.type_to_sql(type, options[:limit], options[:precision], options[:scale])}"  
        end 
        if !options[:default].nil?
           change_column_default(table_name, column_name, options[:default])
        end
        reorg_table(table_name)
      end

      # IDS specific ALTER TABLE statement to add a default clause
      # IDS requires the data type to be explicitly specified when adding the 
      # DEFAULT clause
      def change_column_default(table_name, column_name, default)
        sql_type = nil
        is_nullable = true
        @adapter.columns(table_name).select do |col| 
           if (col.name == column_name)
              sql_type =  @adapter.type_to_sql(col.type, col.limit, col.precision, col.scale)
              is_nullable = col.null 
           end
        end
        # SQL statement which alters column's default value
        change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type} DEFAULT #{@adapter.quote(default)}"
        change_column_sql << " NOT NULL" unless is_nullable 
        stmt = execute(change_column_sql)
        reorg_table(table_name)
        # Ensures to free the resources associated with the statement
        ensure
          IBM_DB.free_stmt(stmt) if stmt
      end

      # IDS specific ALTER TABLE statement to change the nullability of a column
      def change_column_null(table_name,column_name,null,default)
        if !default.nil?
          change_column_default table_name, column_name, default
        end
        sql_type = nil
        @adapter.columns(table_name).select do |col| 
          if (col.name == column_name)
            sql_type =  @adapter.type_to_sql(col.type, col.limit, col.precision, col.scale)
          end
        end
        if !null.nil?
          if !null
            change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type} NOT NULL"
          else
            change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type}"     
          end
          stmt = execute(change_column_sql)
          reorg_table(table_name)
        end

        ensure
          IBM_DB.free_stmt(stmt) if stmt
      end

      # Reorganizes the table for column changes
      def reorg_table(table_name)
        execute("UPDATE STATISTICS FOR TABLE #{table_name}")
      end

      # This method returns the IDS SQL type corresponding to the Rails
      # datetime/timestamp type
      def get_datetime_mapping
        return "datetime year to fraction(5)"
      end

      # This method returns the IDS SQL type corresponding to the Rails
      # time type
      def get_time_mapping
        return "datetime hour to second"
      end

      # This method returns the IDS SQL type corresponding to Rails double type
      def get_double_mapping
        return "double precision"
      end

      # Handling offset/limit as per Informix requirements
      def query_offset_limit(sql, offset, limit)
        if limit != 0
          if !offset.nil?
            # Modifying the SQL to utilize the skip and limit amounts
            sql.gsub!(/SELECT/i,"SELECT SKIP #{offset} LIMIT #{limit}")
          else
            # Modifying the SQL to retrieve only the first #{limit} rows
            sql = sql.gsub!("SELECT","SELECT FIRST #{limit}")
          end
        else
          # Modifying the SQL to ensure that no rows will be returned
          sql.gsub!(/SELECT/i,"SELECT * FROM (SELECT")
          sql << ") WHERE 0 = 1"
        end
      end

      # Handling offset/limit as per Informix requirements
      def query_offset_limit!(sql, offset, limit, options)
        if limit != 0
          if !offset.nil?
            # Modifying the SQL to utilize the skip and limit amounts
            sql.gsub!(/SELECT/i,"SELECT SKIP #{offset} LIMIT #{limit}")
          else
            # Modifying the SQL to retrieve only the first #{limit} rows
            sql = sql.gsub!("SELECT","SELECT FIRST #{limit}")
          end
        else
          # Modifying the SQL to ensure that no rows will be returned
          sql.gsub!(/SELECT/i,"SELECT * FROM (SELECT")
          sql << ") WHERE 0 = 1"
        end
      end

      # Method that returns the last automatically generated ID
      # on the given +@connection+. This method is required by the +insert+ 
      # method. IDS returns the last generated serial value in the SQLCA unlike 
      # DB2 where the generated value has to be retrieved using the 
      # IDENTITY_VAL_LOCAL function. We used the "stmt" parameter to identify 
      # the statement resource from which to get the last generated value
      def last_generated_id(stmt)
        IBM_DB.get_last_serial_value(stmt)
      end

      # This method throws an error when trying to create a default value on a 
      # BLOB/CLOB column for IDS. The documentation states: "if the column is a 
      # BLOB or CLOB datatype, NULL is the only valid default value."
      def set_binary_default(value)
        unless (value == 'NULL')
          raise "Informix Dynamic Server only allows NULL as a valid default value for a BLOB data type"
        end
      end

      # For Informix Dynamic Server, we treat binary value same as we treat a 
      # text value. We support literals by converting the insert into a dummy 
      # insert and an update (See handle_lobs method above)
      def set_binary_value
        "'@@@IBMBINARY@@@'"
      end

      # This method throws an error when trying to create a default value on a 
      # BLOB/CLOB column for IDS.  The documentation states: "if the column is 
      # a BLOB or CLOB datatype, NULL is the only valid default value."
      def set_text_default(value)
        unless (value == 'NULL')
          raise "Informix Dynamic Server only allows NULL as a valid default value for a CLOB data type"
        end
      end

      # For Informix Dynamic Server, the arguments to the meta-data functions
      # need to be in lower-case
      def set_case(value)
        value.downcase
      end
    end # class IBM_IDS
  end # module ConnectionAdapters
end # module ActiveRecord

module Arel
  module Visitors
    class Visitor #opening and closing the class to ensure backward compatibility
    end

    class ToSql < Arel::Visitors::Visitor #opening and closing the class to ensure backward compatibility
      # In case when using Rails-2.3.x there is no arel used due to which the constructor has to be defined explicitly
      # to ensure the same code works on any version of Rails
      
      #Check Arel version
      begin
        @arelVersion = Arel::VERSION.to_i
      rescue
        @arelVersion = 0
      end

      if(@arelVersion >= 3)
        def initialize connection
          @connection     = connection
          @schema_cache   = connection.schema_cache if(connection.respond_to?(:schema_cache))
          @quoted_tables  = {}
          @quoted_columns = {}
          @last_column    = nil
        end
      end
    end

    class IBM_DB < Arel::Visitors::ToSql
      private

      def visit_Arel_Nodes_Limit o, a=nil
        visit o.expr
      end

      def visit_Arel_Nodes_Offset o, a=nil
        visit o.expr
      end

      def visit_Arel_Nodes_SelectStatement o, a=nil
        #Interim  fix for backward compatibility [Arel 4.0.0 and below]
        if self.method(:visit_Arel_Nodes_SelectCore).arity == 1
          sql = [
            (visit(o.with) if o.with),
            o.cores.map { |x| visit_Arel_Nodes_SelectCore x }.join,
            ("ORDER BY #{o.orders.map { |x| visit x }.join(', ')}" unless o.orders.empty?),
          ].compact.join ' '
        else
          sql = [
            (visit(o.with) if o.with),
            o.cores.map { |x| visit_Arel_Nodes_SelectCore x,a }.join,
            ("ORDER BY #{o.orders.map { |x| visit x }.join(', ')}" unless o.orders.empty?),
          ].compact.join ' '
        end

        if o.limit
          limit = visit(o.limit)
        else
          limit = nil
        end

        if o.offset
          offset = visit(o.offset)
        else
          offset = nil
        end
        @connection.add_limit_offset!(sql, {:limit => limit, :offset => offset})
        sql << " #{(visit(o.lock) if o.lock)}"
        return sql
      end

    end
  end
end
