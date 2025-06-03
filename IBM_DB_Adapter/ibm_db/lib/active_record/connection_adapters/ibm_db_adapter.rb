# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006 - 2025          					 |
# +----------------------------------------------------------------------+
# |  Authors: Antonio Cangiano <cangiano@ca.ibm.com>                     |
# |         : Mario Ds Briggs  <mario.briggs@in.ibm.com>                 |
# |         : Praveen Devarao  <praveendrl@in.ibm.com>                   |
# |         : Arvind Gupta     <arvindgu@in.ibm.com>                     |
# +----------------------------------------------------------------------+

require 'active_record/connection_adapters/abstract_adapter'
require 'arel/visitors/visitor'
require 'active_support/core_ext/string/strip'
require 'active_record/type'
require 'active_record/connection_adapters/sql_type_metadata'
require 'active_record/connection_adapters/statement_pool'
require 'active_record/connection_adapters'

# Ensure ActiveRecord and Rails Generators are loaded
require "active_record"
ActiveRecord::ConnectionAdapters.register(
  "ibm_db",
  "ActiveRecord::ConnectionAdapters::IBM_DBAdapter",
  "active_record/connection_adapters/ibm_db_adapter"
)
require "rails/generators/database"

module Rails
  module Generators
    class Database
      DATABASES << "ibm_db" unless DATABASES.include?("ibm_db")

      class << self
        alias_method :original_build, :build

        def build(database_name)
          return IBMDB.new if database_name == "ibm_db"
          original_build(database_name)
        end

        alias_method :original_all, :all

        def all
          original_all + [IBMDB.new]
        end
      end
    end

    class IBMDB < Database
      def name
        "ibm_db"
      end

      def service
        {
          "image" => "ibm_db:latest",
          "restart" => "unless-stopped",
          "networks" => ["default"],
          "volumes" => ["ibm-db-data:/var/lib/ibmdb"],
          "environment" => {
            "IBM_DB_ALLOW_EMPTY_PASSWORD" => "true",
          }
        }
      end

      def port
        nil  # Default DB2 port
      end

      def gem
        ["ibm_db", [">= 5.5"]]
      end

      def base_package
        nil
      end

      def build_package
        nil
      end

      def feature_name
        nil
      end
    end
  end
end

module CallChain
  def self.caller_method(depth = 1)
    parse_caller(caller(depth + 1).first).last
  end

  # Copied from ActionMailer
  def self.parse_caller(at)
    return unless /^(.+?):(\d+)(?::in `(.*)')?/ =~ at

    file   = Regexp.last_match[1]
    line   = Regexp.last_match[2].to_i
    method = Regexp.last_match[3]
    [file, line, method]
  end
end

module ActiveRecord
  class SchemaMigration
    class << self
      def create_table
        return if connection.table_exists?(table_name)

        connection.create_table(table_name, id: false) do |t|
          t.string :version, **connection.internal_string_options_for_primary_key
        end
      end
    end
  end

  module Persistence
    module ClassMethods
      def _insert_record(connection, values, returning) # :nodoc:
        primary_key = self.primary_key
        primary_key_value = nil

        if prefetch_primary_key? && primary_key
          values[primary_key] ||= begin
            primary_key_value = next_sequence_value
            _default_attributes[primary_key].with_cast_value(primary_key_value)
          end
        end

        im = Arel::InsertManager.new(arel_table)

        with_connection do |c|
          if values.empty?
            im.insert(connection.empty_insert_statement_value(primary_key, arel_table[name].relation.name))
          else
            im.insert(values.transform_keys { |name| arel_table[name] })
          end

          connection.insert(
            im, "#{self} Create", primary_key || false, primary_key_value,
            returning: returning
          )
        end
      end
    end
  end

  module ConnectionAdapters
    class SchemaDumper
      private

      def header(stream)
        stream.puts <<~HEADER
          ActiveRecord::Schema[#{ActiveRecord::Migration.current_version}].define(#{define_params}) do
        HEADER
      end

      def default_primary_key?(column)
        schema_type(column) == :integer
      end

      def explicit_primary_key_default?(column)
        column.bigint? and column.name == 'id'
      end

      def unique_constraints_in_create(table, stream)
        if (unique_constraints = @connection.unique_constraints(table)).any?
          add_unique_constraint_statements = unique_constraints.map do |unique_constraint|
            parts = [
              "t.unique_constraint #{unique_constraint.column.inspect}"
            ]

            parts << "deferrable: #{unique_constraint.deferrable.inspect}" if unique_constraint.deferrable

            if unique_constraint.export_name_on_schema_dump?
              parts << "name: #{unique_constraint.name.inspect}"
            end

            "    #{parts.join(', ')}"
          end

          stream.puts add_unique_constraint_statements.sort.join("\n")
        end
      end
    end

    class SchemaCreation
      private

      def visit_TableDefinition(o)
        create_sql = +"CREATE#{table_modifier_in_create(o)} TABLE "
        create_sql << 'IF NOT EXISTS ' if o.if_not_exists
        create_sql << "#{quote_table_name(o.name)} "

        statements = o.columns.map { |c| accept c }
        statements << accept(o.primary_keys) if o.primary_keys

        if supports_indexes_in_create?
          statements.concat(o.indexes.map { |column_name, options| index_in_create(o.name, column_name, options) })
        end

        statements.concat(o.foreign_keys.map { |fk| accept fk }) if use_foreign_keys?

        statements.concat(o.check_constraints.map { |chk| accept chk }) if supports_check_constraints?

        @conn.puts_log "visit_TableDefinition #{@conn.servertype}"
        if !@conn.servertype.instance_of? IBM_IDS
          statements.concat(o.unique_constraints.map { |exc| accept exc }) if supports_unique_constraints?
        end

        create_sql << "(#{statements.join(', ')})" if statements.present?
        add_table_options!(create_sql, o)
        create_sql << " AS (#{to_sql(o.as)}) WITH DATA" if o.as
        create_sql
      end

      def visit_ColumnDefinition(o)
        if @conn.instance_of? IBM_DBAdapter
          @conn.puts_log "visit_ColumnDefinition #{o.name} #{o} #{@conn} #{@conn.servertype}"
        end
        o.sql_type = type_to_sql(o.type, **o.options)
        column_sql = +"#{quote_column_name(o.name)} #{o.sql_type}"
        add_column_options!(column_sql, column_options(o))
        column_sql
      end

      def add_column_options!(sql, options)
        if options_include_default?(options)
          sql << " DEFAULT #{quote_default_expression(options[:default],
                                                      options[:column])}"
        end
        sql << ' GENERATED BY DEFAULT AS IDENTITY (START WITH 1000)' if options[:auto_increment] == true
        sql << ' PRIMARY KEY' if options[:primary_key] == true
        # must explicitly check for :null to allow change_column to work on migrations
        sql << ' NOT NULL' if options[:null] == false
        sql
      end

      def visit_AlterTable(o)
        sql = +"ALTER TABLE #{quote_table_name(o.name)} "
        sql << o.adds.map { |col| accept col }.join(" ")
        sql << o.foreign_key_adds.map { |fk| visit_AddForeignKey fk }.join(" ")
        sql << o.foreign_key_drops.map { |fk| visit_DropForeignKey fk }.join(" ")
        sql << o.check_constraint_adds.map { |con| visit_AddCheckConstraint con }.join(" ")
        sql << o.check_constraint_drops.map { |con| visit_DropCheckConstraint con }.join(" ")
        sql << o.constraint_validations.map { |fk| visit_ValidateConstraint fk }.join(" ")
        sql << o.exclusion_constraint_adds.map { |con| visit_AddExclusionConstraint con }.join(" ")
        sql << o.exclusion_constraint_drops.map { |con| visit_DropExclusionConstraint con }.join(" ")
        sql << o.unique_constraint_adds.map { |con| visit_AddUniqueConstraint con }.join(" ")
        sql << o.unique_constraint_drops.map { |con| visit_DropUniqueConstraint con }.join(" ")
      end

      def visit_ValidateConstraint(name)
        "VALIDATE CONSTRAINT #{quote_column_name(name)}"
      end

      def visit_UniqueConstraintDefinition(o)
        column_name = Array(o.column).map { |column| quote_column_name(column) }.join(", ")

        sql = ["CONSTRAINT"]
        sql << quote_column_name(o.name)
        sql << "UNIQUE"

        if o.using_index
          sql << "USING INDEX #{quote_column_name(o.using_index)}"
        else
          sql << "(#{column_name})"
        end

#        if o.deferrable
#          sql << "DEFERRABLE INITIALLY #{o.deferrable.to_s.upcase}"
#        end

        sql.join(" ")
      end

      def visit_AddExclusionConstraint(o)
        "ADD #{accept(o)}"
      end

      def visit_DropExclusionConstraint(name)
        "DROP CONSTRAINT #{quote_column_name(name)}"
      end

      def visit_AddUniqueConstraint(o)
        "ADD #{accept(o)}"
      end

      def visit_DropUniqueConstraint(name)
        "DROP CONSTRAINT #{quote_column_name(name)}"
      end

    end
  end

  class Base
    # Method required to handle LOBs and XML fields.
    # An after save callback checks if a marker has been inserted through
    # the insert or update, and then proceeds to update that record with
    # the actual large object through a prepared statement (param binding).
    after_save :handle_lobs
    def handle_lobs
#      return unless self.class.with_connection.is_a?(ConnectionAdapters::IBM_DBAdapter)

      self.class.with_connection do |conn|
        if conn.is_a?(ConnectionAdapters::IBM_DBAdapter)
          # Checks that the insert or update had at least a BLOB, CLOB or XML field
          conn.sql.each do |clob_sql|
            next unless clob_sql =~ /BLOB\('(.*)'\)/i ||
                        clob_sql =~ /@@@IBMTEXT@@@/i  ||
                        clob_sql =~ /@@@IBMXML@@@/i   ||
                        clob_sql =~ /@@@IBMBINARY@@@/i

            update_query = "UPDATE #{self.class.table_name} SET ("
            counter = 0
            values = []
            params = []
            # Selects only binary, text and xml columns
            self.class.columns.select { |col| col.sql_type.to_s =~ /blob|binary|clob|text|xml/i }.each do |col|
              update_query << if counter.zero?
                                "#{col.name}".to_s
                              else
                                ",#{col.name}".to_s
                              end

              # Add a '?' for the parameter or a NULL if the value is nil or empty
              # (except for a CLOB field where '' can be a value)
              if self[col.name].nil?  ||
                 self[col.name] == {} ||
                 self[col.name] == [] ||
                 (self[col.name] == '' && !(col.sql_type.to_s =~ /text|clob/i))
                params << 'NULL'
              else
                values << if col.cast_type.is_a?(::ActiveRecord::Type::Serialized)
                            YAML.dump(self[col.name])
                          else
                            self[col.name]
                          end
                params << '?'
              end
              counter += 1
            end

            # no subsequent update is required if no relevant columns are found
            next if counter.zero?

            update_query << ') = '
            # IBM_DB accepts 'SET (column) = NULL'  but not (NULL),
            # therefore the sql needs to be changed for a single NULL field.
            update_query << if params.size == 1 && params[0] == 'NULL'
                              'NULL'
                            else
                              '(' + params.join(',') + ')'
                            end

            update_query << " WHERE #{self.class.primary_key} = ?"
            values << self[self.class.primary_key.downcase]

            begin
              unless (stmt = IBM_DB.prepare(conn.connection, update_query))
                error_msg = IBM_DB.getErrormsg(conn.connection, IBM_DB::DB_CONN)
                if error_msg && !error_msg.empty?
                  raise "Statement prepare for updating LOB/XML column failed : #{error_msg}"
                end
                raise StandardError.new('An unexpected error occurred during update of LOB/XML column')
              end

              conn.log_query(update_query, 'update of LOB/XML field(s)in handle_lobs')

              # rollback any failed LOB/XML field updates (and remove associated marker)
              unless IBM_DB.execute(stmt, values)
                error_msg = "Failed to insert/update LOB/XML field(s) due to: #{IBM_DB.getErrormsg(stmt,
                                                                                               IBM_DB::DB_STMT)}"
                conn.execute('ROLLBACK')
                raise error_msg
              end
            rescue StandardError => e
              raise e
            ensure
              IBM_DB.free_stmt(stmt) if stmt
            end
            # if clob_sql
          # connection.sql.each
          end
          conn.handle_lobs_triggered = true
        end # if conn.is_a?
      end # with_connection
      # if connection.kind_of?
    # handle_lobs
    end

    private :handle_lobs

    # Establishes a connection to a specified database using the credentials provided
    # with the +config+ argument. All the ActiveRecord objects will use this connection
    def self.ibm_db_connection(config)
      # Attempts to load the Ruby driver IBM databases
      # while not already loaded or raises LoadError in case of failure.
      begin
        require 'ibm_db' unless defined? IBM_DB
      rescue LoadError
        raise LoadError, 'Failed to load IBM_DB Ruby driver.'
      end

      # Check if class TableDefinition responds to indexes method to determine if we are on AR 3 or AR 4.
      # This is a interim hack ti ensure backward compatibility. To remove as we move out of AR 3 support or have a better way to determine which version of AR being run against.
      checkClass = ActiveRecord::ConnectionAdapters::TableDefinition.new(self, nil)
      isAr3 = if checkClass.respond_to?(:indexes)
                false
              else
                true
              end
      # Converts all +config+ keys to symbols
      config = config.symbolize_keys

      # Flag to decide if quoted literal replcement should take place. By default it is ON. Set it to OFF if using Pstmt
      set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_ON

      # Retrieves database user credentials from the +config+ hash
      # or raises ArgumentError in case of failure.
      if !config.has_key?(:username) || !config.has_key?(:password)
        raise ArgumentError, "Missing argument(s): Username/Password for #{config[:database]} is not specified"
      end

      if config[:username].to_s.nil? || config[:password].to_s.nil?
        raise ArgumentError, 'Username/Password cannot be nil'
      end

      username = config[:username].to_s
      password = config[:password].to_s

      # Retrieves the database alias (local catalog name) or remote name
      # (for remote TCP/IP connections) from the +config+ hash
      # or raises ArgumentError in case of failure.
      raise ArgumentError, 'Missing argument: a database name needs to be specified.' unless config.has_key?(:database)

      database = config[:database].to_s

      # Providing default schema (username) when not specified
      config[:schema] = config.has_key?(:schema) ? config[:schema].to_s : config[:username].to_s

      if config.has_key?(:parameterized) && config[:parameterized] == true
        set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF
      end

      # Extract connection options from the database configuration
      # (in support to formatting, audit and billing purposes):
      # Retrieve database objects fields in lowercase
      conn_options = { IBM_DB::ATTR_CASE => IBM_DB::CASE_LOWER }
      config.each do |key, value|
        next if value.nil?

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
          connection = IBM_DB.connect(conn_string, '', '', conn_options, set_quoted_literal_replacement)
        else
          # No host implies a local catalog-based connection: +database+ represents catalog alias
          connection = IBM_DB.connect(database, username, password, conn_options, set_quoted_literal_replacement)
        end
        return connection, isAr3, config, conn_options
      rescue StandardError => e
        raise "Failed to connect to [#{database}] due to: #{e}"
      end
      # Verifies that the connection was successful
      raise "An unexpected error occured during connect attempt to [#{database}]" unless connection

    # method self.ibm_db_connection
    end

    def self.ibmdb_connection(config)
      # Method to support alising of adapter name as ibmdb [without underscore]
      ibm_db_connection(config)
    end
  # class Base
  end

  module ConnectionAdapters
    module Quoting
      def lookup_cast_type_from_column(column) # :nodoc:
        lookup_cast_type(column.sql_type_metadata.sql_type)
      end

      module ClassMethods
        def quote_table_name(name)
          if name.start_with? '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
            name = "\"#{name}\""
          else
            name = name.to_s
          end
          name
          # @servertype.check_reserved_words(name).gsub('"', '').gsub("'",'')
        end

        def quote_column_name(name)
          name = name.to_s
          name.gsub('"', '').gsub("'", '')
        end
      end
    end

    module ColumnDumper
      def prepare_column_options(column)
        puts_log 'prepare_column_options'
        spec = {}

        if limit = schema_limit(column)
          spec[:limit] = limit
        end

        if precision = schema_precision(column)
          spec[:precision] = precision
        end

        if scale = schema_scale(column)
          spec[:scale] = scale
        end

        default = schema_default(column) if column.has_default?
        spec[:default] = default unless default.nil?
        spec[:null] = 'false' unless column.null

        if collation = schema_collation(column)
          spec[:collation] = collation
        end

        spec[:comment] = column.comment.inspect if column.comment.present?

        spec
      end

      def schema_limit(column)
        puts_log 'schema_limit'
        limit = column.limit unless column.bigint?
        limit.inspect if limit && limit != native_database_types[column.type.to_sym][:limit]
      end
    # end of module ColumnDumper
    end

    module SchemaStatements
      def internal_string_options_for_primary_key # :nodoc:
        { primary_key: true, null: false }
      end

      def valid_primary_key_options # :nodoc:
        [:limit, :default, :precision, :auto_increment]
      end
      
      def valid_column_definition_options # :nodoc:
        ColumnDefinition::OPTION_NAMES + [:auto_increment]
      end
      
      def drop_table(table_name, options = {})
        if options[:if_exists]
          execute("DROP TABLE IF EXISTS #{quote_table_name(table_name)}")
        else
          execute("DROP TABLE #{quote_table_name(table_name)}", options)
        end
      end

      def create_table_definition(*args, **options)
        puts_log 'create_table_definition SchemaStatements'
        TableDefinition.new(self, *args, **options)
      end

      def unique_constraint_name(table_name, **options)
        options.fetch(:name) do
          column_or_index = Array(options[:column] || options[:using_index]).map(&:to_s)
          identifier = "#{table_name}_#{column_or_index * '_and_'}_unique"
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          "uniq_rails_#{hashed_identifier}"
        end
      end
    # end of Module SchemaStatements
    end

    class IBM_DBColumn < ConnectionAdapters::Column # :nodoc:
      def initialize(*)
        puts_log '15'
        super
      end

      # Used to convert from BLOBs to Strings
      def self.binary_to_string(value)
        # Returns a string removing the eventual BLOB scalar function
        value.to_s.gsub(/"SYSIBM"."BLOB"\('(.*)'\)/i, '\1')
      end
    # class IBM_DBColumn
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
      attr_reader :connection, :servertype, :schema, :app_user, :account, :application, :workstation, :pstmt_support_on,
                  :set_quoted_literal_replacement
      attr_accessor :sql, :handle_lobs_triggered, :sql_parameter_values

      # Name of the adapter
      def adapter_name
        'IBM_DB'
      end

      include Savepoints

      def create_savepoint(name = current_savepoint_name)
        puts_log 'create_savepoint'
        # Turns off auto-committing
        auto_commit_off
        # Create savepoint
        internal_execute("SAVEPOINT #{name} ON ROLLBACK RETAIN CURSORS", 'TRANSACTION')
      end

      class Column < ActiveRecord::ConnectionAdapters::Column
        attr_reader :rowid

        def initialize(*, auto_increment: nil, rowid: false, generated_type: nil, **)
          super
          @auto_increment = auto_increment
          @rowid = rowid
          @generated_type = generated_type
        end

        def self.binary_to_string(value)
          # Returns a string removing the eventual BLOB scalar function
          value.to_s.gsub(/"SYSIBM"."BLOB"\('(.*)'\)/i, '\1')
        end

        # whether the column is auto-populated by the database using a sequence
        def auto_increment?
          @auto_increment
        end

        def auto_incremented_by_db?
          auto_increment? || rowid
        end
        alias_method :auto_incremented_by_db?, :auto_increment?
      end

      class AlterTable < ActiveRecord::ConnectionAdapters::AlterTable
        attr_reader :constraint_validations, :exclusion_constraint_adds, :exclusion_constraint_drops, :unique_constraint_adds, :unique_constraint_drops
        def initialize(td)
          super
          @constraint_validations = []
          @exclusion_constraint_adds = []
          @exclusion_constraint_drops = []
          @unique_constraint_adds = []
          @unique_constraint_drops = []
        end

        def add_unique_constraint(column_name, options)
          @unique_constraint_adds << @td.new_unique_constraint_definition(column_name, options)
        end

        def drop_unique_constraint(unique_constraint_name)
          @unique_constraint_drops << unique_constraint_name
        end
      end

      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
        include ColumnMethods

        attr_reader :exclusion_constraints, :unique_constraints

        def initialize(*, **)
          super
          @exclusion_constraints = []
          @unique_constraints = []
        end

        def exclusion_constraint(expression, **options)
          exclusion_constraints << new_exclusion_constraint_definition(expression, options)
        end

        def unique_constraint(column_name, **options)
          @conn.puts_log "TD unique_constraint column_name = #{column_name}, options = #{options}"
          unique_constraints << new_unique_constraint_definition(column_name, options)
          @conn.puts_log "unique_constraints = #{unique_constraints}"
        end

        def new_unique_constraint_definition(column_name, options) # :nodoc:
          @conn.puts_log "TD new_unique_constraint_definition column_name = #{column_name}, options = #{options}"
          @conn.puts_log caller
          options = @conn.unique_constraint_options(name, column_name, options)
          UniqueConstraintDefinition.new(name, column_name, options)
        end

        def references(*args, **options)
          super(*args, type: :integer, **options)
        end
        alias :belongs_to :references
      end # end of class TableDefinition

      UniqueConstraintDefinition = Struct.new(:table_name, :column, :options) do
        def name
          options[:name]
        end

        def deferrable
          options[:deferrable]
        end

        def using_index
          options[:using_index]
        end

        def export_name_on_schema_dump?
          !ActiveRecord::SchemaDumper.unique_ignore_pattern.match?(name) if name
        end

        def defined_for?(name: nil, column: nil, **options)
          (name.nil? || self.name == name.to_s) &&
            (column.nil? || Array(self.column) == Array(column).map(&:to_s)) &&
            options.all? { |k, v| self.options[k].to_s == v.to_s }
        end
      end

      class StatementPool < ConnectionAdapters::StatementPool # :nodoc:
        private

        def dealloc(stmt)
          # stmt.close unless stmt.closed?
        end
      end

      def build_statement_pool
        StatementPool.new(self.class.type_cast_config_to_integer(@config[:statement_limit]))
      end

      def initialize(args)
        # Caching database connection configuration (+connect+ or +reconnect+ support)\
        connection, ar3, config, conn_options = ActiveRecord::Base.ibm_db_connection(args)
        @config = config
        @connection = connection
        @isAr3 = ar3
        @conn_options     = conn_options
        @database         = config[:database]
        @username         = config[:username]
        @password         = config[:password]
        @debug            = config[:debug]
        if config.has_key?(:host)
          @host           = config[:host]
          @port           = config[:port] || 50000 # default port
        end
        @schema = if config.has_key?(:schema)
                    config[:schema]
                  else
                    config[:username]
                  end
        @security         = config[:security] || nil
        @authentication   = config[:authentication] || nil
        @timeout          = config[:timeout] || 0 # default timeout value is 0

        @app_user = @account = @application = @workstation = nil
        # Caching database connection options (auditing and billing support)
        @app_user         = conn_options[:app_user]     if conn_options.has_key?(:app_user)
        @account          = conn_options[:account]      if conn_options.has_key?(:account)
        @application      = conn_options[:application]  if conn_options.has_key?(:application)
        @workstation      = conn_options[:workstation]  if conn_options.has_key?(:workstation)

        @sql                  = []
        @sql_parameter_values = [] # Used only if pstmt support is turned on

        @handle_lobs_triggered = false

        # Calls the parent class +ConnectionAdapters+' initializer
        super(@config)

        if @connection
          server_info = IBM_DB.server_info(@connection)
          if server_info
            case server_info.DBMS_NAME
            when %r{DB2/}i # DB2 for Linux, Unix and Windows (LUW)
              @servertype = case server_info.DBMS_VER
                            when /09.07/i # DB2 Version 9.7 (Cobra)
                              IBM_DB2_LUW_COBRA.new(self, @isAr3)
                            when /10./i # DB2 version 10.1 and above
                              IBM_DB2_LUW_COBRA.new(self, @isAr3)
                            else # DB2 Version 9.5 or below
                              IBM_DB2_LUW.new(self, @isAr3)
                            end
            when /DB2/i # DB2 for zOS
              case server_info.DBMS_VER
              when /09/             # DB2 for zOS version 9 and version 10
                @servertype = IBM_DB2_ZOS.new(self, @isAr3)
              when /10/
                @servertype = IBM_DB2_ZOS.new(self, @isAr3)
              when /11/
                @servertype = IBM_DB2_ZOS.new(self, @isAr3)
              when /12/
                @servertype = IBM_DB2_ZOS.new(self, @isAr3)
              when /08/             # DB2 for zOS version 8
                @servertype = IBM_DB2_ZOS_8.new(self, @isAr3)
              else # DB2 for zOS version 7
                raise 'Only DB2 z/OS version 8 and above are currently supported'
              end
            when /AS/i                # DB2 for i5 (iSeries)
              @servertype = IBM_DB2_I5.new(self, @isAr3)
            when /IDS/i               # Informix Dynamic Server
              @servertype = IBM_IDS.new(self, @isAr3)
            else
              log('server_info',
                  'Forcing servertype to LUW: DBMS name could not be retrieved. Check if your client version is of the right level')
              warn 'Forcing servertype to LUW: DBMS name could not be retrieved. Check if your client version is of the right level'
              @servertype = IBM_DB2_LUW.new(self, @isAr3)
            end
            @database_version = server_info.DBMS_VER
          else
            error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
            IBM_DB.close(@connection)
            raise "Cannot retrieve server information: #{error_msg}"
          end
        end

        # Executes the +set schema+ statement using the schema identifier provided
        @servertype.set_schema(@schema) if @schema && @schema != @username

        # Check for the start value for id (primary key column). By default it is 1
        @start_id = if config.has_key?(:start_id)
                      config[:start_id]
                    else
                      1
                    end

        # Check Arel version
        begin
          @arelVersion = Arel::VERSION.to_i
        rescue StandardError
          @arelVersion = 0
        end

        @visitor = Arel::Visitors::IBM_DB.new self if @arelVersion >= 3

        if config.has_key?(:parameterized) && config[:parameterized] == true
          @pstmt_support_on = true
          @prepared_statements = true
          @set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF
        else
          @pstmt_support_on = false
          @prepared_statements = false
          @set_quoted_literal_replacement = IBM_DB::QUOTED_LITERAL_REPLACEMENT_ON
        end
      end

      def get_database_version
        @database_version
      end

      def prepared_statements?
        puts_log 'prepared_statements?'
        prepare = @prepared_statements && !prepared_statements_disabled_cache.include?(object_id)
        puts_log "prepare = #{prepare}"
        prepare
      end
      alias prepared_statements prepared_statements?

      def bind_params_length
        999
      end

      # Optional connection attribute: database name space qualifier
      def schema=(name)
        puts_log 'schema='
        return if name == @schema

        @schema = name
        @servertype.set_schema(@schema)
      end

      # Optional connection attribute: authenticated application user
      def app_user=(name)
        puts_log 'app_user='
        return if name == @app_user

        option = { IBM_DB::SQL_ATTR_INFO_USERID => "#{name}" }
        return unless IBM_DB.set_option(@connection, option, 1)

        @app_user = IBM_DB.get_option(@connection, IBM_DB::SQL_ATTR_INFO_USERID, 1)
      end

      # Optional connection attribute: OS account (client workstation)
      def account=(name)
        puts_log 'account='
        return if name == @account

        option = { IBM_DB::SQL_ATTR_INFO_ACCTSTR => "#{name}" }
        return unless IBM_DB.set_option(@connection, option, 1)

        @account = IBM_DB.get_option(@connection, IBM_DB::SQL_ATTR_INFO_ACCTSTR, 1)
      end

      # Optional connection attribute: application name
      def application=(name)
        puts_log 'application='
        return if name == @application

        option = { IBM_DB::SQL_ATTR_INFO_APPLNAME => "#{name}" }
        return unless IBM_DB.set_option(@connection, option, 1)

        @application = IBM_DB.get_option(@connection, IBM_DB::SQL_ATTR_INFO_APPLNAME, 1)
      end

      # Optional connection attribute: client workstation name
      def workstation=(name)
        puts_log 'workstation='
        return if name == @workstation

        option = { IBM_DB::SQL_ATTR_INFO_WRKSTNNAME => "#{name}" }
        return unless IBM_DB.set_option(@connection, option, 1)

        @workstation = IBM_DB.get_option(@connection, IBM_DB::SQL_ATTR_INFO_WRKSTNNAME, 1)
      end

      def self.visitor_for(pool)
        puts_log 'visitor_for'
        Arel::Visitors::IBM_DB.new(pool)
      end

      # Check Arel version
      begin
        @arelVersion = Arel::VERSION.to_i
      rescue StandardError
        @arelVersion = 0
      end
      if @arelVersion < 6
        def to_sql(arel, binds = [])
          if arel.respond_to?(:ast)
            visitor.accept(arel.ast) do
              quote(*binds.shift.reverse)
            end
          else
            arel
          end
        end
      end

      def supports_common_table_expressions?
        true
      end

      # Does this adapter support creating unique constraints?
      def supports_unique_constraints?
        true
      end

      #IBM Db2 does not natively support skipping rows on insert when there's a duplicate key
      def supports_insert_on_duplicate_skip?
        false
      end

      def supports_insert_on_duplicate_update?
        false
      end

      # This adapter supports migrations.
      # Current limitations:
      # +rename_column+ is not currently supported by the IBM data servers
      # +remove_column+ is not currently supported by the DB2 for zOS data server
      # Tables containing columns of XML data type do not support +remove_column+
      def supports_migrations?
        puts_log 'supports_migrations?'
        true
      end

      def use_foreign_keys?
        puts_log 'use_foreign_keys?'
        true
      end

      def supports_datetime_with_precision?
        puts_log 'supports_datetime_with_precision?'
        true
      end

      # This Adapter supports DDL transactions.
      # This means CREATE TABLE and other DDL statements can be carried out as a transaction.
      # That is the statements executed can be ROLLED BACK in case of any error during the process.
      def supports_ddl_transactions?
        puts_log 'supports_ddl_transactions?'
        true
      end

      def supports_explain?
        puts_log 'supports_explain?'
        true
      end

      def supports_lazy_transactions?
        puts_log 'supports_lazy_transactions?'
        true
      end

      def supports_comments?
        true
      end

      def supports_views?
        true
      end

      def log_query(sql, name) # :nodoc:
        puts_log 'log_query'
        # Used by handle_lobs
        log(sql, name) {}
      end

      def supports_partitioned_indexes?
        true
      end

      def supports_foreign_keys?
        true
      end

      def puts_log(val)
        begin
        #         puts val
        rescue StandardError
        end
        return unless @debug == true

        log(" IBM_DB = #{val}", 'TRANSACTION') {}
      end

      #==============================================
      # CONNECTION MANAGEMENT
      #==============================================

      # Tests the connection status
      def active?
        isActive = false
        puts_log "active? #{caller} #{Thread.current}"
        @lock.synchronize do
          puts_log "active? #{@connection}, #{caller}, #{Thread.current}"
          isActive = IBM_DB.active @connection
          puts_log "active? isActive = #{isActive}"
        end
        isActive
      rescue StandardError => e
        puts_log "active? check failure #{e.message}, #{caller}, #{Thread.current}"
        false
      end

      # Private method used by +reconnect!+.
      # It connects to the database with the initially provided credentials
      def connect
        puts_log "connect = #{@connection}, #{caller}, #{Thread.current}"
        # If the type of connection is net based
        raise ArgumentError, 'Username/Password cannot be nil' if @username.nil? || @password.nil?

        begin
          puts_log "Begin connection #{Thread.current}"
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
            puts_log "Connection Established A = #{@connection}"
          else
            # Connects to the database using the local alias (@database)
            # and assigns the connection object (IBM_DB.Connection) to @connection
            @connection = IBM_DB.connect(@database, @username, @password, @conn_options,
                                         @set_quoted_literal_replacement)
            puts_log "Connection Established B = #{@connection}"
          end
          @raw_connection = @connection
        rescue StandardError => e
          warn "Connection to database #{@database} failed: #{e}"
          puts_log "Connection to database #{@database} failed: #{e}"
          @connection = false
        end
        # Sets the schema if different from default (username)
        return unless @schema && @schema != @username

        puts_log "Connection Established = #{@connection}"
        @servertype.set_schema(@schema)
      end
      private :connect

      def reset!
        puts_log "reset! #{caller} #{Thread.current}"
        @lock.synchronize do
          return connect! unless @connection

          rollback_db_transaction

          super
        end
      end

      # Closes the current connection and opens a new one
      def reconnect
        puts_log "reconnect #{caller} #{Thread.current}"
#disconnect!
        @lock.synchronize do
          puts_log "Before reconnection = #{@connection}, #{Thread.current}"
          connect unless @connection
        end
      end

#      def reconnect!(restore_transactions: false)
#        super
#      end

      # Closes the current connection
      def disconnect!
        # Attempts to close the connection. The methods will return:
        # * true if succesfull
        # * false if the connection is already closed
        # * nil if an error is raised
        @lock.synchronize do
          puts_log "disconnect! #{caller}, #{Thread.current}"
          if @connection.nil? || @connection == false
            puts_log "disconnect! return #{caller}, #{Thread.current}"
            return nil
          end

          begin
            super
            IBM_DB.close(@connection)
            puts_log "Connection closed #{Thread.current}"
            @connection = nil
            @raw_connection = nil
          rescue StandardError => e
            puts_log "Connection close failure #{e.message}, #{Thread.current}"
          end
#reset_transaction
        end
      end

      # Check the connection back in to the connection pool
      def close
        pool.checkin self
        disconnect!
      end

      def connected?
        puts_log "connected? #{@connection}"
        !(@connection.nil?)
      end

      #==============================================
      # DATABASE STATEMENTS
      #==============================================

      def create_table(name, id: :primary_key, primary_key: nil, force: nil, **options)
        puts_log "create_table name=#{name}, id=#{id}, primary_key=#{primary_key}, force=#{force}"
        puts_log "create_table Options 1 = #{options}"
        puts_log "primary_key_prefix_type = #{ActiveRecord::Base.primary_key_prefix_type}"
        puts_log caller
        @servertype.setup_for_lob_table
        # Table definition is complete only when a unique index is created on the primarykey column for DB2 V8 on zOS

        # create index on id column if options[:id] is nil or id ==true
        # else check if options[:primary_key]is not nil then create an unique index on that column
        if !id.nil? || !primary_key.nil?
          if !id.nil? && id == true
            @servertype.create_index_after_table(name, 'id')
          elsif !primary_key.nil?
            @servertype.create_index_after_table(name, primary_key.to_s)
          end
        else
          @servertype.create_index_after_table(name, 'id')
        end

        # Just incase if id holds any other data type other than primary_key we override it,
        # otherwise it misses "GENERATED BY DEFAULT AS IDENTITY (START WITH 1000)"
        if !id.nil? && id != false && primary_key.nil? && ActiveRecord::Base.primary_key_prefix_type.nil?
          primary_key = :id
          options[:auto_increment] = true if options[:auto_increment].nil? and %i[integer bigint].include?(id)
        end

        puts_log "create_table Options 2 = #{options}"
        super(name, id: id, primary_key: primary_key, force: force, **options)
      end

      # Calls the servertype select method to fetch the data
      def fetch_data(stmt)
        puts_log 'fetch_data'
        return unless stmt

        begin
          @servertype.select(stmt)
        rescue StandardError => e # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
          raise StatementInvalid, "Failed to retrieve data: #{error_msg}" if error_msg && !error_msg.empty?

          error_msg += ": #{e.message}" unless e.message.empty?
         #raise error_msg
        ensure
          # Ensures to free the resources associated with the statement
          if stmt
            puts_log "Free Statement #{stmt}"
            IBM_DB.free_stmt(stmt)
          end
        end
      end

      def select(sql, name = nil, binds = [], prepare: false, async: false, allow_retry: false)
        puts_log "select sql = #{sql}"
        puts_log "binds = #{binds}"
        puts_log "prepare = #{prepare}"

        # Replaces {"= NULL" with " IS NULL"} OR {"IN (NULL)" with " IS NULL"
        begin
          sql.gsub(/(=\s*NULL|IN\s*\(NULL\))/i, ' IS NULL')
        rescue StandardError
          # ...
        end

        if async && async_enabled?
          if current_transaction.joinable?
            raise AsynchronousQueryInsideTransactionError, 'Asynchronous queries are not allowed inside transactions'
          end

          future_result = async.new(
            pool,
            sql,
            name,
            binds,
            prepare: prepare
          )
          if supports_concurrent_connections? && current_transaction.closed?
            future_result.schedule!(ActiveRecord::Base.asynchronous_queries_session)
          else
            future_result.execute!(self)
          end
          return future_result
        end

        results = []
        cols = []

        stmt = if binds.nil? || binds.empty?
                 internal_execute(sql, name, allow_retry: allow_retry)
               else
                 exec_query_ret_stmt(sql, name, binds, prepare: prepare, async: async, allow_retry: allow_retry)
               end

        if stmt
          cols = IBM_DB.resultCols(stmt)
          results = fetch_data(stmt)
        end

        puts_log "select cols = #{cols}, results = #{results}"

        if @isAr3
          results
        else
          results = ActiveRecord::Result.new(cols, results)
          if async
            results = ActiveRecord::FutureResult::Complete.new(results)
          end
        end

        puts_log "select final results = #{results} #{caller}"
        results
      end

      def translate_exception(exception, message:, sql:, binds:)
        puts_log "translate_exception - exception = #{exception}, message = #{message}"
        puts_log "translate_exception #{caller}"
        error_msg1 = /SQL0803N  One or more values in the INSERT statement, UPDATE statement, or foreign key update caused by a DELETE statement are not valid because the primary key, unique constraint or unique index identified by .* constrains table .* from having duplicate values for the index key/
        error_msg2 = /SQL0204N  .* is an undefined name/
        error_msg3 = /SQL0413N  Overflow occurred during numeric data type conversion/
        error_msg4 = /SQL0407N  Assignment of a NULL value to a NOT NULL column .* is not allowed/
        error_msg5 = /SQL0530N  The insert or update value of the FOREIGN KEY .* is not equal to any value of the parent key of the parent table/
        error_msg6 = /SQL0532N  A parent row cannot be deleted because the relationship .* restricts the deletion/
        error_msg7 = /SQL0433N  Value .* is too long/
        error_msg8 = /CLI0109E  String data right truncation/
        if !error_msg1.match(message).nil?
          puts_log 'RecordNotUnique exception'
          RecordNotUnique.new(message, sql: sql, binds: binds, connection_pool: @pool)
        elsif !error_msg2.match(message).nil?
          puts_log 'ArgumentError exception'
          ArgumentError.new(message)
        elsif !error_msg3.match(message).nil?
          puts_log 'RangeError exception'
          RangeError.new(message, sql: sql, binds: binds, connection_pool: @pool)
        elsif !error_msg4.match(message).nil?
          puts_log 'NotNullViolation exception'
          NotNullViolation.new(message, sql: sql, binds: binds, connection_pool: @pool)
        elsif !error_msg5.match(message).nil? or !error_msg6.match(message).nil?
          puts_log 'InvalidForeignKey exception'
          InvalidForeignKey.new(message, sql: sql, binds: binds, connection_pool: @pool)
        elsif !error_msg7.match(message).nil? or !error_msg8.match(message).nil?
          puts_log 'ValueTooLong exception'
          ValueTooLong.new(message, sql: sql, binds: binds, connection_pool: @pool)
        elsif exception.message.match?(/called on a closed database/i)
          puts_log 'ConnectionNotEstablished exception'
          ConnectionNotEstablished.new(exception, connection_pool: @pool)
        elsif message.strip.start_with?("FrozenError") or
              message.strip.start_with?("ActiveRecord::Encryption::Errors::Encoding:") or
              message.strip.start_with?("ActiveRecord::Encryption::Errors::Encryption") or
              message.strip.start_with?("ActiveRecord::ConnectionFailed")
          exception
        else
          super(message, message: exception, sql: sql, binds: binds)
        end
      end

      def build_truncate_statement(table_name)
        puts_log 'build_truncate_statement'
        "DELETE FROM #{quote_table_name(table_name)}"
      end

      def build_fixture_sql(fixtures, table_name)
        columns = schema_cache.columns_hash(table_name).reject { |_, column| supports_virtual_columns? && column.virtual? }
        puts_log "build_fixture_sql - Table = #{table_name}"
        puts_log "build_fixture_sql - Fixtures = #{fixtures}"
        puts_log "build_fixture_sql - Columns = #{columns}"

        values_list = fixtures.map do |fixture|
          fixture = fixture.stringify_keys
          fixture = fixture.transform_keys(&:downcase)

          unknown_columns = fixture.keys - columns.keys
          if unknown_columns.any?
            raise Fixture::FixtureError, %(table "#{table_name}" has no columns named #{unknown_columns.map(&:inspect).join(', ')}.)
          end

          columns.map do |name, column|
            if fixture.key?(name)
              type = lookup_cast_type_from_column(column)
              with_yaml_fallback(type.serialize(fixture[name]))
            else
              default_insert_value(column)
            end
          end
        end

        table = Arel::Table.new(table_name)
        manager = Arel::InsertManager.new(table)

        if values_list.size == 1
          values = values_list.shift
          new_values = []
          columns.each_key.with_index { |column, i|
            unless values[i].equal?(DEFAULT_INSERT_VALUE)
              new_values << values[i]
              manager.columns << table[column]
            end
          }
          values_list << new_values
        else
          columns.each_key { |column| manager.columns << table[column] }
        end

        manager.values = manager.create_values_list(values_list)
        visitor.compile(manager.ast)
      end

      def build_fixture_statements(fixture_set)
        puts_log "build_fixture_statements - fixture_set = #{fixture_set}"
        fixture_set.filter_map do |table_name, fixtures|
          next if fixtures.empty?
          build_fixture_sql(fixtures, table_name)
        end
      end

      # inserts values from fixtures
      # overridden to handle LOB's fixture insertion, as, in normal inserts callbacks are triggered but during fixture insertion callbacks are not triggered
      # hence only markers like @@@IBMBINARY@@@ will be inserted and are not updated to actual data
      def insert_fixture(fixture, table_name)
        puts_log "insert_fixture = #{fixture}"
        insert_query = if fixture.respond_to?(:keys)
                         "INSERT INTO #{quote_table_name(table_name)} ( #{fixture.keys.join(', ')})"
                       else
                         "INSERT INTO #{quote_table_name(table_name)} ( #{fixture.key_list})"
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
              col = column
              break
            end
          end

          if item.at(1).nil? ||
             item.at(1) == {} ||
             (item.at(1) == '' && !(col.sql_type.to_s =~ /text|clob/i))
            params << 'NULL'

          elsif !col.nil? && (col.sql_type.to_s =~ /blob|binary|clob|text|xml/i)
            #  Add a '?' for the parameter or a NULL if the value is nil or empty
            # (except for a CLOB field where '' can be a value)
            insert_values << quote_value_for_pstmt(item.at(1))
            params << '?'
          else
            insert_values << quote_value_for_pstmt(item.at(1), col)
            params << '?'
          end
        end

        insert_query << ' VALUES (' + params.join(',') + ')'
        unless stmt = IBM_DB.prepare(@connection, insert_query)
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          if error_msg && !error_msg.empty?
            raise "Failed to prepare statement for fixtures insert due to : #{error_msg}"
          end

          raise StandardError.new('An unexpected error occurred during preparing SQL for fixture insert')

        end

        log(insert_query, 'fixture insert') do
          if IBM_DB.execute(stmt, insert_values)
            IBM_DB.free_stmt(stmt) if stmt
          else
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            IBM_DB.free_stmt(stmt) if stmt
            raise "Failed to insert due to: #{error_msg}"
          end
        end
      end

      def empty_insert_statement_value(pkey, table_name)
        puts_log "empty_insert_statement_value pkey = #{pkey}, table_name = #{table_name}"
        puts_log caller

        colCount = columns(table_name).count()
        puts_log "empty_insert_statement_value colCount = #{colCount}"
        val = "DEFAULT, " * (colCount - 1)
        val = val + "DEFAULT"
        " VALUES (#{val})"
      end

      def getTableIdentityColumn(table_name)
        query = "SELECT COLNAME FROM SYSCAT.COLUMNS WHERE TABNAME = #{quote(table_name.upcase)} AND IDENTITY = 'Y'"
        puts_log "getTableIdentityColumn table_name = #{table_name}, query = #{query}"
        rows = execute_without_logging(query).rows
        puts_log "getTableIdentityColumn rows = #{rows}"
        if rows.any?
          return rows.first
        end
      end

      def return_insert (stmt, sql, binds, pk, id_value = nil, returning: nil)
        puts_log "return_insert sql = #{sql}, pk = #{pk}, returning = #{returning}"
        @sql << sql

        table_name = sql[/\AINSERT\s+INTO\s+([^\s\(]+)/i, 1]
        rowID = getTableIdentityColumn(table_name)
        #Identity column exist.
        if Array(rowID).any?
          val = @servertype.last_generated_id(stmt)
          #returning required is just an ID, or nothing is expected to return
          only_returning_id = Array(returning).empty? ||
                             (Array(returning).size == 1 && Array(rowID).first == Array(returning).first)
          unless only_returning_id
            cols = Array(returning).join(', ')
            query = "SELECT #{cols} FROM #{table_name} WHERE #{Array(rowID).first} = #{val}"
            puts_log "return_insert val = #{val}, cols = #{cols}, table_name = #{table_name}"
            puts_log "return_insert query = #{query}"
            rows = execute_without_logging(query).rows
            puts_log "return_insert rows = #{rows}"
            return rows.first
          end
        end

        puts_log "return_insert id_value = #{id_value}, val = #{val}"
        if !returning.nil?
          [id_value || val]
        else
          id_value || val
        end
      end

      # Perform an insert and returns the last ID generated.
      # This can be the ID passed to the method or the one auto-generated by the database,
      # and retrieved by the +last_generated_id+ method.
      def insert_direct(sql, name = nil, _pk = nil, id_value = nil, returning: nil)
        puts_log "insert_direct sql = #{sql}, name = #{name}, _pk = #{_pk}, returning = #{returning}"
        if @handle_lobs_triggered # Ensure the array of sql is cleared if they have been handled in the callback
          @sql = []
          @handle_lobs_triggered = false
        end

        return unless stmt = execute(sql, name)

        begin
          return_insert(stmt, sql, nil, _pk, id_value, returning: returning)
          # Ensures to free the resources associated with the statement
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end
      end

      def insert(arel, name = nil, pk = nil, id_value = nil, sequence_name = nil, binds = [], returning: nil)
        puts_log "insert Binds P = #{binds}, name = #{name}, pk = #{pk}, id_value = #{id_value}, returning = #{returning}"
        puts_log caller
        if @arelVersion < 6
          sql = to_sql(arel)
          binds = binds
        else
          sql, binds = to_sql_and_binds(arel, binds)
        end

        puts_log "insert Binds A = #{binds}"
        puts_log "insert SQL = #{sql}"
        # unless IBM_DBAdapter.respond_to?(:exec_insert)
        return insert_direct(sql, name, pk, id_value, returning: returning) if binds.nil? || binds.empty?

        ActiveRecord::Base.clear_query_caches_for_current_thread

        return unless stmt = exec_insert_db2(sql, name, binds, pk, sequence_name, returning)

        begin
          return_insert(stmt, sql, binds, pk, id_value, returning: returning)
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end
      end

      def exec_insert_db2(sql, name = nil, binds = [], pk = nil, sequence_name = nil, returning = nil)
        puts_log "exec_insert_db2 sql = #{sql}, name = #{name}, binds = #{binds}, pk = #{pk}, returning = #{returning}"
        sql, binds = sql_for_insert(sql, pk, binds, returning)
        exec_query_ret_stmt(sql, name, binds, prepare: false)
      end

      def build_insert_sql(insert) # :nodoc:
        sql = +"INSERT #{insert.into} #{insert.values_list}"
        sql
      end

      def last_inserted_id(result)
        puts_log 'last_inserted_id'
        result
      end

      def exec_insert(sql, name = nil, binds = [], pk = nil, sequence_name = nil, returning: nil) # :nodoc:
        puts_log 'exec_insert'
        insert(sql)
      end

      # Praveen
      # Performs an insert using the prepared statement and returns the last ID generated.
      # This can be the ID passed to the method or the one auto-generated by the database,
      # and retrieved by the +last_generated_id+ method.
      def prepared_insert(pstmt, param_array = nil, id_value = nil)
        puts_log 'prepared_insert'
        if @handle_lobs_triggered # Ensure the array of sql is cleared if they have been handled in the callback
          @sql                   = []
          @sql_parameter_values  = []
          @handle_lobs_triggered = false
        end

        ActiveRecord::Base.clear_query_caches_for_current_thread

        begin
          if execute_prepared_stmt(pstmt, param_array)
            @sql << @prepared_sql
            @sql_parameter_values << param_array
            id_value || @servertype.last_generated_id(pstmt)
          end
        rescue StandardError => e
          raise e
        ensure
          IBM_DB.free_stmt(pstmt) if pstmt
        end
      end

      # Praveen
      # Prepares and logs +sql+ commands and
      # returns a +IBM_DB.Statement+ object.
      def prepare(sql, name = nil)
        puts_log 'prepare'
        # The +log+ method is defined in the parent class +AbstractAdapter+
        @prepared_sql = sql
        log(sql, name) do
          @servertype.prepare(sql, name)
        end
      end

      # Praveen
      # Executes the prepared statement
      # ReturnsTrue on success and False on Failure
      def execute_prepared_stmt(pstmt, param_array = nil)
        puts_log 'execute_prepared_stmt'
        puts_log "Param array = #{param_array}"
        param_array = nil if !param_array.nil? && param_array.size < 1

        if !IBM_DB.execute(pstmt, param_array)
          error_msg = IBM_DB.getErrormsg(pstmt, IBM_DB::DB_STMT)
          puts_log "Error = #{error_msg}"
          IBM_DB.free_stmt(pstmt) if pstmt
          raise StatementInvalid, error_msg
        else
          true
        end
      end

      READ_QUERY = ActiveRecord::ConnectionAdapters::AbstractAdapter.build_read_query_regexp(
        :desc, :describe
      ) # :nodoc:
      private_constant :READ_QUERY

      def write_query?(sql) # :nodoc:
        !READ_QUERY.match?(sql)
      rescue ArgumentError # Invalid encoding
        !READ_QUERY.match?(sql.b)
      end

      def explain(arel, binds = [], options = [])
        sql = "EXPLAIN ALL SET QUERYNO = 1 FOR #{to_sql(arel, binds)}"
        stmt = execute(sql, 'EXPLAIN')
        result = select("select * from explain_statement where explain_level = 'P' and queryno = 1", 'EXPLAIN')
        result[0]['total_cost'].to_s
      # Ensures to free the resources associated with the statement
      ensure
        IBM_DB.free_stmt(stmt) if stmt
      end

      def execute_without_logging(sql, name = nil, binds = [], prepare: true, async: false)
        puts_log "execute_without_logging sql = #{sql}, name = #{name}, binds = #{binds}"

        sql = transform_query(sql)
        check_if_write_query(sql)
        mark_transaction_written_if_write(sql)
        cols = nil
        results = nil
        begin
          param_array = type_casted_binds(binds)
          puts_log "execute_without_logging Param array = #{param_array}"
          puts_log "execute_without_logging #{caller}"

          stmt = @servertype.prepare(sql, name)
          @statements[sql] = stmt if prepare

          puts_log "execute_without_logging Statement = #{stmt}"

          execute_prepared_stmt(stmt, param_array)

          if stmt and sql.strip.upcase.start_with?("SELECT")
            cols = IBM_DB.resultCols(stmt)
            results = fetch_data(stmt) if stmt

            puts_log "execute_without_logging columns = #{cols}"
            puts_log "execute_without_logging result = #{results}"
          end
        rescue => e
          raise translate_exception_class(e, sql, binds)
        ensure
          @offset = @limit = nil
        end
        if @isAr3
          results
        elsif results.nil?
          ActiveRecord::Result.empty
        else
          ActiveRecord::Result.new(cols, results)
        end
      end

      # Executes +sql+ statement in the context of this connection using
      # +binds+ as the bind substitutes.  +name+ is logged along with
      # the executed +sql+ statement.
      # Here prepare argument is not used, by default this method creates prepared statment and execute.
      def exec_query_ret_stmt(sql, name = 'SQL', binds = [], prepare: false, async: false, allow_retry: false)
        puts_log "exec_query_ret_stmt #{sql}"
        sql = transform_query(sql)
        check_if_write_query(sql)
        mark_transaction_written_if_write(sql)
        begin
          puts_log "SQL = #{sql}"
          puts_log "Binds = #{binds}"
          param_array = type_casted_binds(binds)
          puts_log "Param array = #{param_array}"
          puts_log "Prepare flag = #{prepare}"
          puts_log "#{caller}"

          stmt = @servertype.prepare(sql, name)
          @statements[sql] = stmt if prepare

          puts_log "Statement = #{stmt}"
          log(sql, name, binds, param_array, async: async) do
            with_raw_connection(allow_retry: allow_retry) do |conn|
              return false unless stmt
              return stmt if execute_prepared_stmt(stmt, param_array)
            end
          end
        rescue => e
          raise translate_exception_class(e, sql, binds)
        ensure
          @offset = @limit = nil
        end
      end

      def internal_exec_query(sql, name = 'SQL', binds = [], prepare: false, async: false)
        select_prepared(sql, name, binds, prepare: prepare, async: async)
      end

      def select_prepared(sql, name = nil, binds = [], prepare: true, async: false)
        puts_log 'select_prepared'
        puts_log "select_prepared sql before = #{sql}"
        puts_log "select_prepared Binds = #{binds}"
        stmt = exec_query_ret_stmt(sql, name, binds, prepare: prepare, async: async)
        cols = nil
        results = nil

        if stmt and sql.strip.upcase.start_with?("SELECT")
          cols = IBM_DB.resultCols(stmt)

          results = fetch_data(stmt) if stmt

          puts_log "select_prepared columns = #{cols}"
          puts_log "select_prepared sql after = #{sql}"
          puts_log "select_prepared result = #{results}"
        end
        if @isAr3
          results
        elsif results.nil?
          ActiveRecord::Result.empty
        else
          ActiveRecord::Result.new(cols, results)
        end
      end

      def check_if_write_query(sql) # For rails 7.1 just remove this function as it will be defined in AbstractAdapter class
        return unless preventing_writes? && write_query?(sql)

        raise ActiveRecord::ReadOnlyError, "Write query attempted while in readonly mode: #{sql}"
      end

      # Executes and logs +sql+ commands and
      # returns a +IBM_DB.Statement+ object.
      def execute(sql, name = nil, allow_retry: false)
        puts_log "execute #{sql}"
        ActiveRecord::Base.clear_query_caches_for_current_thread
        stmt = internal_execute(sql, name, allow_retry: allow_retry)
        cols = nil
        results = nil
        puts_log "raw_execute stmt = #{stmt}"
        if sql.strip.upcase.start_with?("SELECT") and stmt
          cols = IBM_DB.resultCols(stmt)
          results = fetch_data(stmt)

          puts_log "execute columns = #{cols}"
          puts_log "execute result = #{results}"
        end
        if results.nil? || results.empty?
          stmt
        else
          formatted = cols.each_with_index.map { |col, i| { col => results[i].first } }
          puts_log "raw_execute formatted = #{formatted}"
          formatted.to_s
        end
      end

      def raw_execute(sql, name, async: false, allow_retry: false, materialize_transactions: true)
        # Logs and execute the sql instructions.
        # The +log+ method is defined in the parent class +AbstractAdapter+
        # sql='INSERT INTO ar_internal_metadata (key, value, created_at, updated_at) VALUES ('10', '10', '10', '10')
        puts_log "raw_execute sql = #{sql} #{Thread.current}"
        log(sql, name, async: async) do
          with_raw_connection(allow_retry: allow_retry, materialize_transactions: materialize_transactions) do |conn|
            verify!
            puts_log "raw_execute executes query #{Thread.current}"
            result= @servertype.execute(sql, name)
            puts_log "raw_execute result = #{result} #{Thread.current}"
            verified!
            result
          end
        end
      end

      # Executes an "UPDATE" SQL statement
      def update_direct(sql, name = nil)
        puts_log 'update_direct'
        if @handle_lobs_triggered # Ensure the array of sql is cleared if they have been handled in the callback
          @sql = []
          @handle_lobs_triggered = false
        end

        # Logs and execute the given sql query.
        return unless stmt = execute(sql, name)

        begin
          @sql << sql
          # Retrieves the number of affected rows
          IBM_DB.num_rows(stmt)
          # Ensures to free the resources associated with the statement
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end
      end

      # Praveen
      def prepared_update(pstmt, param_array = nil)
        puts_log 'prepared_update'
        if @handle_lobs_triggered # Ensure the array of sql is cleared if they have been handled in the callback
          @sql                   = []
          @sql_parameter_values  = []
          @handle_lobs_triggered = false
        end

        ActiveRecord::Base.clear_query_caches_for_current_thread

        begin
          if execute_prepared_stmt(pstmt, param_array)
            @sql << @prepared_sql
            @sql_parameter_values << param_array
            # Retrieves the number of affected rows
            IBM_DB.num_rows(pstmt)
            # Ensures to free the resources associated with the statement
          end
        rescue StandardError => e
          raise e
        ensure
          IBM_DB.free_stmt(pstmt) if pstmt
        end
      end
      # The delete method executes the delete
      # statement and returns the number of affected rows.
      # The method is an alias for +update+
      alias prepared_delete prepared_update

      def update(arel, name = nil, binds = [])
        puts_log 'update'
        if @arelVersion < 6
          sql = to_sql(arel)
        else
          sql, binds = to_sql_and_binds(arel, binds)
        end

        # Make sure the WHERE clause handles NULL's correctly
        sqlarray = sql.split(/\s*WHERE\s*/)
        size = sqlarray.size
        if size > 1
          sql = sqlarray[0] + ' WHERE '
          if size > 2
            1.upto size - 2 do |index|
              sqlarray[index].gsub!(/(=\s*NULL|IN\s*\(NULL\))/i, ' IS NULL') unless sqlarray[index].nil?
              sql = sql + sqlarray[index] + ' WHERE '
            end
          end
          sqlarray[size - 1].gsub!(/(=\s*NULL|IN\s*\(NULL\))/i, ' IS NULL') unless sqlarray[size - 1].nil?
          sql += sqlarray[size - 1]
        end

        ActiveRecord::Base.clear_query_caches_for_current_thread

        if binds.nil? || binds.empty?
          update_direct(sql, name)
        else
          begin
            if stmt = exec_query_ret_stmt(sql, name, binds, prepare: true)
              IBM_DB.num_rows(stmt)
            end
          ensure
            IBM_DB.free_stmt(stmt) if stmt
          end
        end
      end

      alias delete update

      def auto_commit_on
        puts_log 'Inside auto_commit_on'
        IBM_DB.autocommit @connection, IBM_DB::SQL_AUTOCOMMIT_ON
        ac = IBM_DB::autocommit @connection
        if ac != 1
          puts_log "Cannot set IBM_DB::AUTOCOMMIT_ON"
        else
          puts_log "AUTOCOMMIT_ON set"
        end
      end

      def auto_commit_off
        puts_log 'auto_commit_off'
        IBM_DB.autocommit(@connection, IBM_DB::SQL_AUTOCOMMIT_OFF)
        ac = IBM_DB::autocommit @connection
        if ac != 0
          puts_log "Cannot set IBM_DB::AUTOCOMMIT_OFF"
        else
          puts_log "AUTOCOMMIT_OFF set"
        end
      end

      # Begins the transaction (and turns off auto-committing)
      def begin_db_transaction
        puts_log 'begin_db_transaction'
        log('begin transaction', 'TRANSACTION') do
          with_raw_connection(allow_retry: true, materialize_transactions: false) do |conn|
            # Turns off the auto-commit
            auto_commit_off
            verified!
          end
        end
      end

      # Commits the transaction and turns on auto-committing
      def commit_db_transaction
        puts_log 'commit_db_transaction'
        log('commit transaction', 'TRANSACTION') do
          with_raw_connection(allow_retry: true, materialize_transactions: false) do |conn|
            # Commits the transaction

            IBM_DB.commit @connection
          end
        rescue StandardError
          nil
        end
        # Turns on auto-committing
        auto_commit_on
      end

      # Rolls back the transaction and turns on auto-committing. Must be
      # done if the transaction block raises an exception or returns false
      def rollback_db_transaction
        puts_log 'rollback_db_transaction'
        log('rollback transaction', 'TRANSACTION') do
          with_raw_connection(allow_retry: true, materialize_transactions: false) do |conn|
            # ROLLBACK the transaction

            IBM_DB.rollback(@connection)
          end
        rescue StandardError
          nil
        end
        ActiveRecord::Base.clear_query_caches_for_current_thread
        # Turns on auto-committing
        auto_commit_on
      end

      def default_sequence_name(table, column) # :nodoc:
        puts_log "default_sequence_name table = #{table}, column = #{column}"
        return nil if column.is_a?(Array)
        "#{table}_#{column}_seq"
      end

      #==============================================
      # QUOTING
      #==============================================

      def quote_value_for_pstmt(value, column = nil)
        puts_log 'quote_value_for_pstmt'
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
        when String, ActiveSupport::Multibyte::Chars
          value = value.to_s
          if column && column.sql_type.to_s =~ /int|serial|float/i
            column.sql_type.to_s =~ /int|serial/i ? value.to_i : value.to_f

          else
            value
          end
        when NilClass                 then nil
        when TrueClass                then 1
        when FalseClass               then 0
        when Float, Integer, Integer then value
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

      # Quotes a given string, escaping single quote (') characters.
      def quote_string(string)
        puts_log 'quote_string'
        string.gsub(/'/, "''")
        # string.gsub('\\', '\&\&').gsub("'", "''")
      end

      # *true* is represented by a smallint 1, *false*
      # by 0, as no native boolean type exists in DB2.
      # Numerics are not quoted in DB2.
      def quoted_true
        puts_log 'quoted_true'
        '1'.freeze
      end

      def quoted_false
        puts_log 'quoted_false'
        '0'.freeze
      end

      def unquoted_true
        puts_log 'unquoted_true'
        1
      end

      def unquoted_false
        puts_log 'unquoted_false'
        0
      end

      def quote_table_name(name)
        puts_log "quote_table_name #{name}"
        puts_log caller
        if name.start_with? '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
          name = "\"#{name}\""
        else
          name = name.to_s
        end
        puts_log "name = #{name}"
        name
        # @servertype.check_reserved_words(name).gsub('"', '').gsub("'",'')
      end

      def quote_column_name(name)
        puts_log "quote_column_name #{name}"
        @servertype.check_reserved_words(name).gsub('"', '').gsub("'", '')
      end

      def quoted_binary(value)
        puts_log 'quoted_binary'
        "CAST(x'#{value.hex}' AS BLOB)"
      end
      #==============================================
      # SCHEMA STATEMENTS
      #==============================================

      # Returns a Hash of mappings from the abstract data types to the native
      # database types
      def native_database_types
        {
          primary_key: { name: @servertype.primary_key_definition(@start_id) },
          string: { name: 'varchar', limit: 400 },
          text: { name: 'clob' },
          integer: { name: 'integer' },
          float: { name: 'float' },
          datetime: { name: 'timestamp' },
          timestamp: { name: 'timestamp' },
          time: { name: 'time' },
          date: { name: 'date' },
          binary: { name: 'blob' },

          # IBM data servers don't have a native boolean type.
          # A boolean can be represented  by a smallint,
          # adopting the convention that False is 0 and True is 1
          boolean: { name: 'smallint' },
          xml: { name: 'xml' },
          decimal: { name: 'decimal' },
          rowid: { name: 'rowid' }, # rowid is a supported datatype on z/OS and i/5
          serial: { name: 'serial' }, # rowid is a supported datatype on Informix Dynamic Server
          char: { name: 'char' },
          double: { name: @servertype.get_double_mapping },
          decfloat: { name: 'decfloat' },
          graphic: { name: 'graphic' },
          vargraphic: { name: 'vargraphic' },
          bigint: { name: 'bigint' }
        }
      end

      def build_conn_str_for_dbops
        puts_log 'build_conn_str_for_dbops'
        connect_str = 'DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;'
        unless @host.nil?
          connect_str << "HOSTNAME=#{@host};"
          connect_str << "PORT=#{@port};"
          connect_str << 'PROTOCOL=TCPIP;'
        end
        connect_str << "UID=#{@username};PWD=#{@password};"
        connect_str
      end

      def drop_database(dbName)
        puts_log 'drop_database'
        connect_str = build_conn_str_for_dbops

        # Ensure connection is closed before trying to drop a database.
        # As a connect call would have been made by call seeing connection in active
        disconnect!

        begin
          dropConn = IBM_DB.connect(connect_str, '', '')
        rescue StandardError => e
          raise "Failed to connect to server due to: #{e}"
        end

        if IBM_DB.dropDB(dropConn, dbName)
          IBM_DB.close(dropConn)
          true
        else
          error = IBM_DB.getErrormsg(dropConn, IBM_DB::DB_CONN)
          IBM_DB.close(dropConn)
          raise "Could not drop Database due to: #{error}"
        end
      end

      def create_database(dbName, codeSet = nil, mode = nil)
        puts_log 'create_database'
        connect_str = build_conn_str_for_dbops

        # Ensure connection is closed before trying to drop a database.
        # As a connect call would have been made by call seeing connection in active
        disconnect!

        begin
          createConn = IBM_DB.connect(connect_str, '', '')
        rescue StandardError => e
          raise "Failed to connect to server due to: #{e}"
        end

        if IBM_DB.createDB(createConn, dbName, codeSet, mode)
          IBM_DB.close(createConn)
          true
        else
          error = IBM_DB.getErrormsg(createConn, IBM_DB::DB_CONN)
          IBM_DB.close(createConn)
          raise "Could not create Database due to: #{error}"
        end
      end

      def valid_type?(type)
        !native_database_types[type].nil?
      end

      # IBM data servers do not support limits on certain data types (unlike MySQL)
      # Limit is supported for the {float, decimal, numeric, varchar, clob, blob, graphic, vargraphic} data types.
      def type_to_sql(type, limit = nil, precision = nil, scale = nil)
        puts_log 'type_to_sql'
        puts_log "Type = #{type}, Limit = #{limit}"
        puts_log "type_to_sql = #{caller}"

        if type.to_sym == :binary and limit.class == Hash and limit.has_key?('limit'.to_sym)
          sql_segment = native_database_types[type.to_sym][:name].to_s
          sql_segment << "(#{limit[:limit]})"
          return sql_segment
        end

        if type.to_sym == :datetime and limit.class == Hash and limit.has_key?('precision'.to_sym)
          sql_segment = native_database_types[type.to_sym][:name].to_s
          if limit[:precision].nil?
            return sql_segment
          elsif (0..12).include?(limit[:precision])
            sql_segment << "(#{limit[:precision]})"
            return sql_segment
          else
            raise ArgumentError,
                  "No #{sql_segment} type has precision of #{limit[:precision]}. The allowed range of precision is from 0 to 12"
          end
        end

        if type.to_sym == :string and limit.class == Hash and limit.has_key?('limit'.to_sym)
          sql_segment = native_database_types[type.to_sym][:name].to_s
          sql_segment << "(#{limit[:limit]})"
          return sql_segment
        end

        if type.to_sym == :decimal
          precision = limit[:precision] if limit.class == Hash && limit.has_key?('precision'.to_sym)
          scale = limit[:scale] if limit.class == Hash && limit.has_key?('scale'.to_sym)
          sql_segment = native_database_types[type.to_sym][:name].to_s
          if !precision.nil? && !scale.nil?
            sql_segment << "(#{precision},#{scale})"
            return sql_segment
          elsif scale.nil? && !precision.nil?
            sql_segment << "(#{precision})"
            return sql_segment
          elsif precision.nil? && !scale.nil?
            raise ArgumentError, 'Error adding decimal column: precision cannot be empty if scale is specified'
          else
            return sql_segment
          end
        end

        if type.to_sym == :decfloat
          sql_segment = native_database_types[type.to_sym][:name].to_s
          sql_segment << "(#{precision})" unless precision.nil?
          return sql_segment
        end

        if type.to_sym == :vargraphic
          sql_segment = native_database_types[type.to_sym][:name].to_s
          if limit.class == Hash
            return 'vargraphic(1)' unless limit.has_key?('limit'.to_sym)

            limit1 = limit[:limit]
            sql_segment << "(#{limit1})"

          else
            return 'vargraphic(1)' if limit.nil?

            sql_segment << "(#{limit})"

          end
          return sql_segment
        end

        if type.to_sym == :graphic
          sql_segment = native_database_types[type.to_sym][:name].to_s
          if limit.class == Hash
            return 'graphic(1)' unless limit.has_key?('limit'.to_sym)

            limit1 = limit[:limit]
            sql_segment << "(#{limit1})"

          else
            return 'graphic(1)' if limit.nil?

            sql_segment << "(#{limit})"

          end
          return sql_segment
        end

        if limit.class == Hash
          return super(type) if limit.has_key?('limit'.to_sym).nil?
        elsif limit.nil?
          return super(type)
        end

        # strip off limits on data types not supporting them
        if @servertype.limit_not_supported_types.include? type.to_sym
          native_database_types[type.to_sym][:name].to_s
        elsif type.to_sym == :boolean
          'smallint'
        else
          super(type)
        end
      end

      # Returns the maximum length a table alias identifier can be.
      # IBM data servers (cross-platform) table limit is 128 characters
      def table_alias_length
        128
      end

      # Retrieves table's metadata for a specified shema name
      def tables(_name = nil)
        puts_log 'tables'
        # Initializes the tables array
        tables = []
        # Retrieve table's metadata through IBM_DB driver
        stmt = IBM_DB.tables(@connection, nil,
                             @servertype.set_case(@schema))
        if stmt
          begin
            # Fetches all the records available
            while tab = IBM_DB.fetch_assoc(stmt)
              # Adds the lowercase table name to the array
              if tab['table_type'] == 'TABLE' # check, so that only tables are dumped,IBM_DB.tables also returns views,alias etc in the schema
                tables << tab['table_name'].downcase
              end
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve table metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of table metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
            raise error_msg
          ensure
            IBM_DB.free_stmt(stmt) if stmt # Free resources associated with the statement
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve tables metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during retrieval of table metadata')

        end
        # Returns the tables array
        tables
      end

      # Retrieves views's metadata for a specified shema name
      def views
        puts_log 'views'
        # Initializes the tables array
        tables = []
        # Retrieve view's metadata through IBM_DB driver
        stmt = IBM_DB.tables(@connection, nil, @servertype.set_case(@schema))
        if stmt
          begin
            # Fetches all the records available
            while tab = IBM_DB.fetch_assoc(stmt)
              # Adds the lowercase view's name to the array
              if tab['table_type'] == 'V' # check, so that only views are dumped,IBM_DB.tables also returns tables,alias etc in the schema
                tables << tab['table_name'].downcase
              end
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve views metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of views metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
            raise error_msg
          ensure
            IBM_DB.free_stmt(stmt) if stmt # Free resources associated with the statement
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve tables metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during retrieval of views metadata')

        end
        # Returns the tables array
        tables
      end

      # Returns the primary key of the mentioned table
      def primary_key(table_name)
        puts_log 'primary_key'
        pk_name = []
        stmt = IBM_DB.primary_keys(@connection, nil,
                                   @servertype.set_case(@schema),
                                   @servertype.set_case(table_name.to_s))
        if stmt
          begin
            while (pk_index_row = IBM_DB.fetch_array(stmt))
              puts_log "Primary_keys = #{pk_index_row}"
              pk_name << pk_index_row[3].downcase
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve primarykey metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of primary key metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
            raise error_msg
          ensure # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve primary key metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during primary key retrieval')

        end
        if pk_name.length == 1
          pk_name[0]
        elsif pk_name.empty?
          nil
        else
          pk_name
        end
      end

      # Returns an array of non-primary key indexes for a specified table name
      def indexes(table_name, _name = nil)
        puts_log 'indexes'
        puts_log "Table = #{table_name}"
        # to_s required because +table_name+ may be a symbol.
        table_name = table_name.to_s
        # Checks if a blank table name has been given.
        # If so it returns an empty array of columns.
        return [] if table_name.strip.empty?

        indexes = []
        pk_index = nil
        index_schema = []

        # fetch the primary keys of the table using function primary_keys
        # TABLE_SCHEM:: pk_index[1]
        # TABLE_NAME:: pk_index[2]
        # COLUMN_NAME:: pk_index[3]
        # PK_NAME:: pk_index[5]
        stmt = IBM_DB.primary_keys(@connection, nil,
                                   @servertype.set_case(@schema),
                                   @servertype.set_case(table_name))
        if stmt
          begin
            while (pk_index_row = IBM_DB.fetch_array(stmt))
              puts_log "Primary keys = #{pk_index_row}"
              puts_log "pk_index = #{pk_index}"
              next unless pk_index_row[5]

              pk_index_name = pk_index_row[5].downcase
              pk_index_columns = [pk_index_row[3].downcase] # COLUMN_NAME
              if pk_index
                pk_index.columns << pk_index_columns
              else
                pk_index = IndexDefinition.new(table_name, pk_index_name, true, pk_index_columns)
              end
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve primarykey metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of primary key metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
            raise error_msg
          ensure # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve primary key metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during primary key retrieval')

        end

        # Query table statistics for all indexes on the table
        # "TABLE_NAME:   #{index_stats[2]}"
        # "NON_UNIQUE:   #{index_stats[3]}"
        # "INDEX_NAME:   #{index_stats[5]}"
        # "COLUMN_NAME:  #{index_stats[8]}"
        stmt = IBM_DB.statistics(@connection, nil,
                                 @servertype.set_case(@schema),
                                 @servertype.set_case(table_name), 1)
        if stmt
          begin
            while (index_stats = IBM_DB.fetch_array(stmt))
              is_composite = false
              next unless index_stats[5] # INDEX_NAME

              index_name = index_stats[5].downcase
              index_unique = (index_stats[3] == 0)
              index_columns = [index_stats[8].downcase] # COLUMN_NAME
              index_qualifier = index_stats[4].downcase # Index_Qualifier
              # Create an IndexDefinition object and add to the indexes array
              i = 0
              indexes.each do |index|
                if index.name == index_name && index_schema[i] == index_qualifier
                  # index.columns = index.columns + index_columns
                  index.columns.concat index_columns
                  is_composite = true
                end
                i += 1
              end

              next if is_composite

              sql = "select remarks from syscat.indexes where tabname = #{quote(table_name.upcase)} and indname = #{quote(index_stats[5])}"
              comment = single_value_from_rows(execute_without_logging(sql, "SCHEMA").rows)

              indexes << IndexDefinition.new(table_name, index_name, index_unique, index_columns,
                                             comment: comment)
              index_schema << index_qualifier
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve index metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of index metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
            raise error_msg
          ensure # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve index metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during index retrieval')

        end

        # remove the primary key index entry.... should not be dumped by the dumper

        puts_log "Indexes 1 = #{pk_index}"
        i = 0
        indexes.each do |index|
          indexes.delete_at(i) if pk_index && index.columns == pk_index.columns
          i += 1
        end
        # Returns the indexes array
        puts_log "Indexes 2 = #{indexes}"
        indexes
      end

      # Mapping IBM data servers SQL datatypes to Ruby data types
      def simplified_type2(field_type)
        puts_log 'simplified_type2'
        case field_type
        # if +field_type+ contains 'for bit data' handle it as a binary
        when /for bit data/i
          'binary'
        when /smallint/i
          'boolean'
        when /int|serial/i
          'integer'
        when /decimal|numeric|decfloat/i
          'decimal'
        when /float|double|real/i
          'float'
        when /timestamp|datetime/i
          'timestamp'
        when /time/i
          'time'
        when /date/i
          'date'
        when /vargraphic/i
          'vargraphic'
        when /graphic/i
          'graphic'
        when /clob|text/i
          'text'
        when /xml/i
          'xml'
        when /blob|binary/i
          'binary'
        when /char/i
          'string'
        when /boolean/i
          'boolean'
        when /rowid/i # rowid is a supported datatype on z/OS and i/5
          'rowid'
        end
      end # method simplified_type

      # Mapping IBM data servers SQL datatypes to Ruby data types
      def simplified_type(field_type)
        puts_log 'simplified_type'
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
          :datetime
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
        when /rowid/i # rowid is a supported datatype on z/OS and i/5
          :rowid
        end
      end # method simplified_type

      def extract_value_from_default(default)
        case default
        when /IDENTITY GENERATED BY DEFAULT/i
          nil
        when /^null$/i
          nil
        # Quoted types
        when /^'(.*)'$/m
          ::Regexp.last_match(1).gsub("''", "'")
        # Quoted types
        when /^"(.*)"$/m
          ::Regexp.last_match(1).gsub('""', '"')
        # Numeric types
        when /\A-?\d+(\.\d*)?\z/
          ::Regexp.last_match(0)
        else
          # Anything else is blank or some function
          # and we can't know the value of that, so return nil.
          nil
        end
      end

      # Returns an array of Column objects for the table specified by +table_name+
      def columns(table_name)
        default_blob_length = 1048576
        # to_s required because it may be a symbol.
        puts_log "def columns #{table_name}"
        puts_log caller
        table_name = @servertype.set_case(table_name.to_s)

        # Checks if a blank table name has been given.
        # If so it returns an empty array
        return [] if table_name.strip.empty?

        # +columns+ will contain the resulting array
        columns = []
        # Statement required to access all the columns information
        stmt = IBM_DB.columns(@connection, nil,
                              @servertype.set_case(@schema),
                              @servertype.set_case(table_name))
        #       sql = "select * from sysibm.sqlcolumns where table_name = #{quote(table_name.upcase)}"
        if @debug == true
          sql = "select * from syscat.columns  where tabname = #{quote(table_name.upcase)}"
          puts_log "SYSIBM.SQLCOLUMNS = #{execute_without_logging(sql).rows}"
        end

        pri_key = primary_key(table_name)

        if stmt
          begin
            # Fetches all the columns and assigns them to col.
            # +col+ is an hash with keys/value pairs for a column
            while col = IBM_DB.fetch_assoc(stmt)
              rowid = false
              puts_log "def columns fecthed = #{col}"
              column_name = col['column_name'].downcase
              sql = "select 1 FROM syscat.columns where tabname = #{quote(table_name.upcase)} and generated = 'D' and colname = '#{col['column_name']}'"
              rows = execute_without_logging(sql).rows
              auto_increment = rows.dig(0, 0) == 1 ? true : nil
              puts_log "def columns auto_increment = #{rows}, #{auto_increment}"

              # Assigns the column default value.
              column_default_value = col['column_def']
              default_value = extract_value_from_default(column_default_value)
              # Assigns the column type
              column_type = col['type_name'].downcase

              if Array(pri_key).include?(column_name) and column_type =~ /integer|bigint/i
                rowid = true
                puts_log "def columns rowid = true"
              end
              # Assigns the field length (size) for the column

              column_length = if column_type =~ /integer|bigint/i
                                col['buffer_length']
                              else
                                col['column_size']
                              end
              column_scale = col['decimal_digits']
              # The initializer of the class Column, requires the +column_length+ to be declared
              # between brackets after the datatype(e.g VARCHAR(50)) for :string and :text types.
              # If it's a "for bit data" field it does a subsitution in place, if not
              # it appends the (column_length) string on the supported data types
              if column_type.match(/decimal|numeric/)
                if column_length > 0 and column_scale > 0
                  column_type << "(#{column_length},#{column_scale})"
                elsif column_length > 0 and column_scale == 0
                  column_type << "(#{column_length})"
                end
              elsif column_type.match(/timestamp/)
                column_type << "(#{column_scale})"
              elsif column_type.match(/varchar/) and column_length > 0
                column_type << "(#{column_length})"
              end

              column_nullable = col['nullable'] == 1
              # Make sure the hidden column (db2_generated_rowid_for_lobs) in DB2 z/OS isn't added to the list
              next if column_name.match(/db2_generated_rowid_for_lobs/i)

              puts_log "Column type = #{column_type}"
              ruby_type = simplified_type(column_type)
              puts_log "Ruby type after = #{ruby_type}"
              precision = extract_precision(ruby_type)

              if column_type.match(/timestamp|integer|bigint|date|time|blob/i)
                if column_type.match(/timestamp/i)
                  precision = column_scale
                  unless default_value.nil?
                    default_value[10] = ' '
                    default_value[13] = ':'
                    default_value[16] = ':'
                  end
                elsif column_type.match(/time/i)
                  unless default_value.nil?
                    default_value[2] = ':'
                    default_value[5] = ':'
                  end
                end
                column_scale = nil
                if !(column_type.match(/blob/i) and column_length != default_blob_length) and !column_type.match(/bigint/i)
                  column_length = nil
                end
              elsif column_type.match(/decimal|numeric/)
                precision = column_length
                column_length = nil
              end

              column_type = 'boolean' if ruby_type.to_s == 'boolean'

              puts_log "Inside def columns() - default_value = #{default_value}, column_default_value = #{column_default_value}"
              default_function = extract_default_function(default_value, column_default_value)
              puts_log "Inside def columns() - default_function = #{default_function}"

              sqltype_metadata = SqlTypeMetadata.new(
                # sql_type: sql_type,
                sql_type: column_type,
                type: ruby_type,
                limit: column_length,
                precision: precision,
                scale: column_scale
              )

              columns << Column.new(column_name, default_value, sqltype_metadata, column_nullable, default_function,
                                    comment: col['remarks'], auto_increment: auto_increment, rowid: rowid)
            end
          rescue StandardError => e # Handle driver fetch errors
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve column metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of column metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
          #             raise error_msg
          ensure # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve column metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during retrieval of columns metadata')

        end
        # Returns the columns array
        puts_log "Inside def columns() #{columns}"
        columns
      end

      def extract_precision(sql_type)
        ::Regexp.last_match(1).to_i if sql_type =~ /\((\d+)(,\d+)?\)/
      end

      def extract_default_function(default_value, default)
        default if has_default_function?(default_value, default)
      end

      def has_default_function?(default_value, default)
        !default_value && /\w+\(.*\)|CURRENT_TIME|CURRENT_DATE|CURRENT_TIMESTAMP/.match?(default)
        !default_value && /(\w+\(.*\)|CURRENT(?:[_\s]TIME|[_\s]DATE|[_\s]TIMESTAMP))/i.match?(default)
      end

      def foreign_keys(table_name)
        puts_log "foreign_keys #{table_name}"
        # fetch the foreign keys of the table using function foreign_keys
        # PKTABLE_NAME::  fk_row[2] Name of the table containing the primary key.
        # PKCOLUMN_NAME:: fk_row[3] Name of the column containing the primary key.
        # FKTABLE_NAME::  fk_row[6] Name of the table containing the foreign key.
        # FKCOLUMN_NAME:: fk_row[7] Name of the column containing the foreign key.
        # FK_NAME:: 		 fk_row[11] The name of the foreign key.

        table_name = @servertype.set_case(table_name.to_s)
        foreignKeys = []
        fks_temp = []
        stmt = IBM_DB.foreignkeys(@connection, nil,
                                  @servertype.set_case(@schema),
                                  @servertype.set_case(table_name), 'FK_TABLE')

        if stmt
          begin
            while (fk_row = IBM_DB.fetch_array(stmt))
              puts_log "foreign_keys fetch = #{fk_row}"
              options = {
                column: fk_row[7].downcase,
                name: fk_row[11].downcase,
                primary_key: fk_row[3].downcase
              }
              options[:on_update] = extract_foreign_key_action(fk_row[9])
              options[:on_delete] = extract_foreign_key_action(fk_row[10])
              fks_temp << ForeignKeyDefinition.new(fk_row[6].downcase, fk_row[2].downcase, options)
            end

            fks_temp.each do |fkst|
              comb = false
              if foreignKeys.size > 0
                foreignKeys.each_with_index do |fks, ind|
                  if fks.name == fkst.name
                    if foreignKeys[ind].column.kind_of?(Array)
                      foreignKeys[ind].column << fkst.column
                      foreignKeys[ind].primary_key << fkst.primary_key
                    else
                      options = {
                        name: fks.name,
                        on_update: nil,
                        on_delete: nil
                      }

                      options[:column] = []
                      options[:column] << fks.column
                      options[:column] << fkst.column

                      options[:primary_key] = []
                      options[:primary_key] << fks.primary_key
                      options[:primary_key] << fkst.primary_key

                      foreignKeys[ind] = ForeignKeyDefinition.new(fks.from_table, fks.to_table, options)
                    end
                    comb = true
                    break
                  end
                end
                foreignKeys << fkst if !comb
              else
                foreignKeys << fkst
              end
            end

          rescue StandardError => e # Handle driver fetch errors
            puts_log "foreign_keys e = #{e}"
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            raise "Failed to retrieve foreign key metadata during fetch: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of foreign key metadata'
            error_msg += ": #{e.message}" unless e.message.empty?
          #             raise error_msg
          ensure # Free resources associated with the statement
            IBM_DB.free_stmt(stmt) if stmt
          end
        else # Handle driver execution errors
          error_msg = IBM_DB.getErrormsg(@connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve foreign key metadata due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during foreign key retrieval')

        end
        # Returns the foreignKeys array
        foreignKeys
      end

      def extract_foreign_key_action(specifier) # :nodoc:
        puts_log 'extract_foreign_key_action'
        case specifier
        when 0 then :cascade
        when 1 then :restrict
        when 2 then :nullify
        end
      end

      def supports_disable_referential_integrity? # :nodoc:
        true
      end

      def disable_referential_integrity # :nodoc:
        puts_log 'disable_referential_integrity'
        alter_foreign_keys(tables, true) if supports_disable_referential_integrity?

        yield
      ensure
        alter_foreign_keys(tables, false) if supports_disable_referential_integrity?
      end

      def alter_foreign_keys(tables, not_enforced)
        puts_log 'alter_foreign_keys'
        enforced = not_enforced ? 'NOT ENFORCED' : 'ENFORCED'
        tables.each do |table|
          foreign_keys(table).each do |fk|
            puts_log "alter_foreign_keys fk = #{fk}"
            execute("ALTER TABLE #{@servertype.set_case(fk.from_table)} ALTER FOREIGN KEY #{@servertype.set_case(fk.name)} #{enforced}")
          end
        end
      end

      def primary_keys(table_name) # :nodoc:
        puts_log 'primary_keys'
        raise ArgumentError unless table_name.present?

        primary_key(table_name)
      end

      # Adds comment for given table column or drops it if +comment+ is a +nil+
      def change_column_comment(table_name, column_name, comment_or_changes) # :nodoc:
        puts_log 'change_column_comment'
        clear_cache!
        comment = extract_new_comment_value(comment_or_changes)
        if comment.nil?
          execute "COMMENT ON COLUMN #{quote_table_name(table_name)}.#{quote_column_name(column_name)} IS ''"
        else
          execute "COMMENT ON COLUMN #{quote_table_name(table_name)}.#{quote_column_name(column_name)} IS #{quote(comment)}"
        end
      end

      # Adds comment for given table or drops it if +comment+ is a +nil+
      def change_table_comment(table_name, comment_or_changes) # :nodoc:
        puts_log "change_table_comment table_name = #{table_name}, comment_or_changes = #{comment_or_changes}"
        clear_cache!
        comment = extract_new_comment_value(comment_or_changes)
        puts_log "change_table_comment new_comment = #{comment}"
        if comment.nil?
          execute "COMMENT ON TABLE #{quote_table_name(table_name)} IS ''"
        else
          execute "COMMENT ON TABLE #{quote_table_name(table_name)} IS #{quote(comment)}"
        end
      end

      def add_column(table_name, column_name, type, **options) # :nodoc:
        puts_log 'add_column'
        clear_cache!
        puts_log "add_column info #{table_name}, #{column_name}, #{type}, #{options}"
        puts_log caller
        if (!type.nil? && type.to_s == 'primary_key') or (options.key?(:primary_key) and options[:primary_key] == true)
          if !type.nil? and type.to_s != 'primary_key'
            execute "ALTER TABLE #{table_name} ADD COLUMN #{column_name} #{type} NOT NULL DEFAULT 0"
          else
            execute "ALTER TABLE #{table_name} ADD COLUMN #{column_name} INTEGER NOT NULL DEFAULT 0"
          end
          execute "ALTER TABLE #{table_name} alter column #{column_name} drop default"
          execute "ALTER TABLE #{table_name} alter column #{column_name} set GENERATED BY DEFAULT AS IDENTITY (START WITH 1000)"
          execute "ALTER TABLE #{table_name} add primary key (#{column_name})"
        else
          super
        end
        change_column_comment(table_name, column_name, options[:comment]) if options.key?(:comment)
      end

      def table_comment(table_name) # :nodoc:
        puts_log "table_comment table_name = #{table_name}"
        sql = "select remarks from syscat.tables where tabname = #{quote(table_name.upcase)}"
        single_value_from_rows(execute_without_logging(sql).rows)
      end

      def add_index(table_name, column_name, **options) # :nodoc:
        puts_log 'add_index'
        index, algorithm, if_not_exists = add_index_options(table_name, column_name, **options)

        return if if_not_exists && index_exists?(table_name, column_name, name: index.name)

        if_not_exists = false if if_not_exists
        create_index = CreateIndexDefinition.new(index, algorithm, if_not_exists)
        result = execute schema_creation.accept(create_index)

        execute "COMMENT ON INDEX #{quote_column_name(index.name)} IS #{quote(index.comment)}" if index.comment
        result
      end

      def add_timestamps(table_name, **options)
        puts_log "add_timestamps #{table_name}"
        fragments = add_timestamps_for_alter(table_name, **options)
        execute "ALTER TABLE #{quote_table_name(table_name)} #{fragments.join(' ')}"
      end

      def query_values(sql, _name = nil) # :nodoc:
        puts_log 'query_values'
        select_prepared(sql).rows.map(&:first)
      end

      def data_source_sql(name = nil, type: nil)
        puts_log 'data_source_sql'
        puts_log "servertype = #{@servertype}"
        if @servertype.instance_of? IBM_IDS
          sql = "SELECT tabname FROM systables WHERE"
          if type || name
            conditions = []
            conditions << "tabtype = #{quote(type.upcase)}" if type
            conditions << "tabname = #{quote(name.upcase)}" if name
            sql << " #{conditions.join(' AND ')}"
          end
          sql << " AND owner = #{quote(@schema.upcase)}"
        else
          sql = +'SELECT tabname FROM (SELECT tabname, type FROM syscat.tables '
          sql << " WHERE tabschema = #{quote(@schema.upcase)}) subquery"
          if type || name
            conditions = []
            conditions << "subquery.type = #{quote(type.upcase)}" if type
            conditions << "subquery.tabname = #{quote(name.upcase)}" if name
            sql << " WHERE #{conditions.join(' AND ')}"
          end
        end
        sql
      end

      # Returns an array of table names defined in the database.
      def tables
        puts_log 'tables'
        query_values(data_source_sql(type: 'T'), 'SCHEMA').map(&:downcase)
      end

      # Checks to see if the table +table_name+ exists on the database.
      #
      #   table_exists?(:developers)
      #
      def table_exists?(table_name)
        puts_log "table_exists? = #{table_name}"
        query_values(data_source_sql(table_name, type: 'T'), 'SCHEMA').any? if table_name.present?
      rescue NotImplementedError
        tables.include?(table_name.to_s)
      end

      # Returns an array of view names defined in the database.
      def views
        puts_log 'views'
        query_values(data_source_sql(type: 'V'), 'SCHEMA').map(&:downcase)
      end

      # Checks to see if the view +view_name+ exists on the database.
      #
      #   view_exists?(:ebooks)
      #
      def view_exists?(view_name)
        puts_log 'view_exists?'
        query_values(data_source_sql(view_name, type: 'V'), 'SCHEMA').any? if view_name.present?
      rescue NotImplementedError
        views.include?(view_name.to_s)
      end

      # Returns the relation names useable to back Active Record models.
      # For most adapters this means all #tables and #views.
      def data_sources
        puts_log 'data_sources'
        query_values(data_source_sql, 'SCHEMA').map(&:downcase)
      rescue NotImplementedError
        tables | views
      end

      def create_schema_dumper(options)
        puts_log 'create_schema_dumper'
        SchemaDumper.create(self, options)
      end

      def table_options(table_name) # :nodoc:
        puts_log 'table_options'
        return unless comment = table_comment(table_name)

        { comment: comment }
      end

      def remove_columns(table_name, *column_names, type: nil, **options)
        if column_names.empty?
          raise ArgumentError.new('You must specify at least one column name. Example: remove_columns(:people, :first_name)')
        end

        remove_column_fragments = remove_columns_for_alter(table_name, *column_names, type: type, **options)
        execute "ALTER TABLE #{quote_table_name(table_name)} #{remove_column_fragments.join(' ')}"
      end

      # Renames a table.
      # ==== Example
      # rename_table('octopuses', 'octopi')
      # Overriden to satisfy IBM data servers syntax
      def rename_table(name, new_name, **options)
        puts_log "rename_table name = #{name}, new_name = #{new_name}"
        validate_table_length!(new_name) unless options[:_uses_legacy_table_name]
        clear_cache!
        schema_cache.clear_data_source_cache!(name.to_s)
        schema_cache.clear_data_source_cache!(new_name.to_s)
        name = quote_column_name(name)
        new_name = quote_column_name(new_name)
        puts_log "90 old_table = #{name}, new_table = #{new_name}"
        # SQL rename table statement
        index_list = indexes(name)
        puts_log "Index List = #{index_list}"
        drop_table_indexes(index_list)
        rename_table_sql = "RENAME TABLE #{name} TO #{new_name}"
        stmt = execute(rename_table_sql)
        create_table_indexes(index_list, new_name)
      # Ensures to free the resources associated with the statement
      ensure
        IBM_DB.free_stmt(stmt) if stmt
      end

      def add_reference(table_name, ref_name, **options) # :nodoc:
        puts_log "add_reference table_name = #{table_name}, ref_name = #{ref_name}"
        super(table_name, ref_name, type: :integer, **options)
      end
      alias :add_belongs_to :add_reference

      def drop_table_indexes(index_list)
        puts_log "drop_table_indexes index_list = #{index_list}"
        index_list.each do |indexs|
          remove_index(indexs.table, name: indexs.name)
        end
      end

      def create_table_indexes(index_list, new_table)
        puts_log "create_table_indexes index_list = #{index_list}, new_table = #{new_table}"
        index_list.each do |indexs|
          generated_index_name = index_name(indexs.table, column: indexs.columns)
          custom_index_name = indexs.name

          if generated_index_name == custom_index_name
            add_index(new_table, indexs.columns, unique: indexs.unique)
          else
            add_index(new_table, indexs.columns, name: custom_index_name, unique: indexs.unique)
          end
        end
      end

      def drop_column_indexes(index_list, column_name)
        puts_log 'drop_column_indexes'
        index_list.each do |indexs|
          if indexs.columns.class == Array
            next unless indexs.columns.include?(column_name)
          elsif indexs.columns != column_name
            next
          end
          remove_index(indexs.table, name: indexs.name)
        end
      end

      def create_column_indexes(index_list, column_name, new_column_name)
        puts_log 'create_column_indexes'
        index_list.each do |indexs|
          generated_index_name = index_name(indexs.table, column: indexs.columns)
          custom_index_name = indexs.name
          if indexs.columns.class == Array
            next unless indexs.columns.include?(column_name)

            indexs.columns[indexs.columns.index(column_name)] = new_column_name
          else
            next if indexs.columns != column_name

            indexs.columns = new_column_name
          end

          if generated_index_name == custom_index_name
            add_index(indexs.table, indexs.columns, unique: indexs.unique)
          else
            add_index(indexs.table, indexs.columns, name: custom_index_name, unique: indexs.unique)
          end
        end
      end

      # Renames a column in a table.
      def rename_column(table_name, column_name, new_column_name) # :nodoc:
        puts_log 'rename_column'
        column_name = quote_column_name(column_name)
        new_column_name = quote_column_name(new_column_name)
        puts_log "rename_column #{table_name}, #{column_name}, #{new_column_name}"
        clear_cache!
        unique_indexes = unique_constraints(table_name)
        puts_log "rename_column Unique Indexes = #{unique_indexes}"
        remove_unique_constraint_byColumn(unique_indexes)
        index_list = indexes(table_name)
        puts_log "rename_column Index List = #{index_list}"
        fkey_list = foreign_keys(table_name)
        puts_log "rename_column ForeignKey = #{fkey_list}"
        drop_column_indexes(index_list, column_name)
        fkey_removed = remove_foreign_key_byColumn(fkey_list, table_name, column_name)
        execute("ALTER TABLE #{quote_table_name(table_name)} #{rename_column_sql(table_name, column_name,
                                                                                 new_column_name)}")
        add_unique_constraint_byColumn(unique_indexes, new_column_name)
        add_foreign_keyList(fkey_list, table_name, column_name, new_column_name) if fkey_removed
        create_column_indexes(index_list, column_name, new_column_name)
      end

      def add_unique_constraint_byColumn(unique_indexes, new_column_name)
        puts_log "add_unique_constraint_byColumn = #{unique_indexes}"
        unique_indexes.each do |unq|
          add_unique_constraint(unq.table_name, new_column_name, name: unq.name)
        end
      end

      def remove_unique_constraint_byColumn(unique_indexes)
        puts_log "remove_unique_constraint_byColumn = #{unique_indexes}"
        unique_indexes.each do |unq|
          remove_unique_constraint(unq.table_name, unq.column, name: unq.name)
        end
      end

      def add_foreign_keyList(fkey_list, table_name, column_name, new_column_name)
        puts_log "add_foreign_keyList = #{table_name}, #{column_name}, #{fkey_list}"
        fkey_list.each do |fkey|
          if fkey.options[:column] == column_name
            add_foreign_key(table_name, strip_table_name_prefix_and_suffix(fkey.to_table), column: new_column_name)
          end
        end
      end

      def remove_foreign_key_byColumn(fkey_list, table_name, column_name)
        puts_log "remove_foreign_key_byColumn = #{table_name}, #{column_name}, #{fkey_list}"
        fkey_removed = false
        fkey_list.each do |fkey|
          if fkey.options[:column] == column_name
            remove_foreign_key(table_name, column: column_name)
            fkey_removed = true
          end
        end
        fkey_removed
      end

      def rename_index(table_name, old_name, new_name)
        puts_log 'rename_index'
        old_name = old_name.to_s
        new_name = new_name.to_s
        validate_index_length!(table_name, new_name)

        # this is a naive implementation; some DBs may support this more efficiently (PostgreSQL, for instance)
        old_index_def = indexes(table_name).detect { |i| i.name == old_name }
        return unless old_index_def

        remove_index(table_name, name: old_name)
        add_index(table_name, old_index_def.columns, name: new_name, unique: old_index_def.unique)
      end

      # Removes the column from the table definition.
      # ===== Examples
      #  remove_column(:suppliers, :qualification)
      def remove_column(table_name, column_name, _type = nil, **options)
        puts_log 'remove_column'
        return if options[:if_exists] == true && !column_exists?(table_name, column_name)

        @servertype.remove_column(table_name, column_name)
      end

      # Changes the column's definition according to the new options.
      # See TableDefinition#column for details of the options you can use.
      # ===== Examples
      #  change_column(:suppliers, :name, :string, :limit => 80)
      #  change_column(:accounts, :description, :text)
      def change_column(table_name, column_name, type, options = {})
        puts_log 'change_column'
        @servertype.change_column(table_name, column_name, type, options)
        change_column_comment(table_name, column_name, options[:comment]) if options.key?(:comment)
      end

      # Add distinct clause to the sql if there is no order by specified
      def distinct(columns, order_by)
        puts_log 'distinct'
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
        puts_log 'change_column_default'
        @servertype.change_column_default(table_name, column_name, default)
      end

      # Changes the nullability value of a column
      def change_column_null(table_name, column_name, null, default = nil)
        puts_log 'change_column_null'
         validate_change_column_null_argument!(null)
        @servertype.change_column_null(table_name, column_name, null, default)
      end

      def build_change_column_default_definition(table_name, column_name, default_or_changes) # :nodoc:
        column = column_for(table_name, column_name)
        return unless column

        default = extract_new_default_value(default_or_changes)
        ChangeColumnDefaultDefinition.new(column, default)
      end

      def build_change_column_definition(table_name, column_name, type, **options) # :nodoc:
        column = column_for(table_name, column_name)
        type ||= column.sql_type

        unless options.key?(:default)
          options[:default] = column.default
        end

        unless options.key?(:null)
          options[:null] = column.null
        end

        unless options.key?(:comment)
          options[:comment] = column.comment
        end

        if options[:collation] == :no_collation
          options.delete(:collation)
        else
          options[:collation] ||= column.collation if text_type?(type)
        end

        unless options.key?(:auto_increment)
          options[:auto_increment] = column.auto_increment?
        end

        td = create_table_definition(table_name)
        cd = td.new_column_definition(column.name, type, **options)
        ChangeColumnDefinition.new(cd, column.name)
      end

      def text_type?(type)
        TYPE_MAP.lookup(type).is_a?(Type::String) || TYPE_MAP.lookup(type).is_a?(Type::Text)
      end

      def quote_schema_name(schema_name)
        quote_table_name(schema_name)
      end

       # Creates a schema for the given schema name.
      def create_schema(schema_name, force: nil, if_not_exists: nil)
        puts_log "create_schema #{schema_name}"
        drop_schema(schema_name, if_exists: true)

        execute("CREATE SCHEMA #{quote_schema_name(schema_name)}")
      end

      # Drops the schema for the given schema name.
      def drop_schema(schema_name, **options)
        puts_log "drop_schema = #{schema_name}"
        schema_list = internal_exec_query("select schemaname from syscat.schemata where schemaname=#{quote(schema_name.upcase)}", "SCHEMA")
        puts_log "drop_schema schema_list = #{schema_list.columns}, #{schema_list.rows}"
        execute("DROP SCHEMA #{quote_schema_name(schema_name)} RESTRICT") if schema_list.rows.size > 0
      end

      def add_unique_constraint(table_name, column_name = nil, **options)
        puts_log "add_unique_constraint = #{table_name}, #{column_name}, #{options}"
        options = unique_constraint_options(table_name, column_name, options)
        at = create_alter_table(table_name)
        at.add_unique_constraint(column_name, options)

        execute schema_creation.accept(at)
      end

      def unique_constraint_options(table_name, column_name, options) # :nodoc:
        assert_valid_deferrable(options[:deferrable])

        if column_name && options[:using_index]
          raise ArgumentError, "Cannot specify both column_name and :using_index options."
        end

        options = options.dup
        options[:name] ||= unique_constraint_name(table_name, column: column_name, **options)
        options
      end

      # Returns an array of unique constraints for the given table.
      # The unique constraints are represented as UniqueConstraintDefinition objects.
      def unique_constraints(table_name)
        puts_log "unique_constraints table_name = #{table_name}"
        puts_log "unique_constraints #{caller}"
        table_name = table_name.to_s
        if table_name.include?(".")
          schema_name, table_name = table_name.split(".")
          puts_log "unique_constraints split schema_name = #{schema_name}, table_name = #{table_name}"
        else
          schema_name = @schema
        end
        unique_info = internal_exec_query(<<~SQL, "SCHEMA")
          SELECT KEYCOL.CONSTNAME, KEYCOL.COLNAME FROM SYSCAT.KEYCOLUSE KEYCOL
              INNER JOIN SYSCAT.TABCONST TABCONST ON KEYCOL.CONSTNAME=TABCONST.CONSTNAME
              WHERE TABCONST.TABSCHEMA=#{quote(schema_name.upcase)} and
              TABCONST.TABNAME=#{quote(table_name.upcase)} and TABCONST.TYPE='U'
        SQL

        puts_log "unique_constraints unique_info = #{unique_info.columns}, #{unique_info.rows}"
        unique_info.map do |row|
          puts_log "unique_constraints row = #{row}"
          columns = []
          columns << row["colname"].downcase

          options = {
            name: row["constname"].downcase,
            deferrable: false
          }

          UniqueConstraintDefinition.new(table_name, columns, options)
        end
      end

      def remove_unique_constraint(table_name, column_name = nil, **options)
        puts_log "remove_unique_constraint table_name = #{table_name}, column_name = #{column_name}, options = #{options}"
        unique_name_to_delete = unique_constraint_for!(table_name, column: column_name, **options).name

        puts_log "remove_unique_constraint unique_name_to_delete = #{unique_name_to_delete}"
        at = create_alter_table(table_name)
        at.drop_unique_constraint(unique_name_to_delete)

        execute schema_creation.accept(at)
      end

      def unique_constraint_name(table_name, **options)
        puts_log "unique_constraint_name table_name = #{table_name}, options = #{options}"
        options.fetch(:name) do
          column_or_index = Array(options[:column] || options[:using_index]).map(&:to_s)
          identifier = "#{table_name}_#{column_or_index * '_and_'}_unique"
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          "uniq_rails_#{hashed_identifier}"
        end
      end

      def unique_constraint_for(table_name, **options)
        puts_log "unique_constraint_for table_name = #{table_name}, options = #{options}"
        name = unique_constraint_name(table_name, **options)
        puts_log "unique_constraint_for name = #{name}"
        uq = unique_constraints(table_name)
        puts_log "unique_constraint_for unique_constraints = #{uq}"
        uq.detect { |unique_constraint| unique_constraint.defined_for?(name: name) }
      end

      def unique_constraint_for!(table_name, column: nil, **options)
        puts_log "unique_constraint_for! table_name = #{table_name}, column = #{column}, options = #{options}"
        unique_constraint_for(table_name, column: column, **options) ||
        raise(ArgumentError, "Table '#{table_name}' has no unique constraint for #{column || options}")
      end

      def foreign_key_name(table_name, options)
        puts_log "foreign_key_name table_name = #{table_name}, options = #{options}"
        options.fetch(:name) do
          columns = Array(options.fetch(:column)).map(&:to_s)
          identifier = "#{table_name}_#{columns * '_and_'}_fk"
          hashed_identifier = OpenSSL::Digest::SHA256.hexdigest(identifier).first(10)

          "fk_rails_#{hashed_identifier}"
        end
      end

      def foreign_key_for(from_table, **options)
        puts_log "foreign_key_for from_table = #{from_table}, options = #{options}"
        return unless use_foreign_keys?
        fks = foreign_keys(from_table)
        puts_log "foreign_key_for fks = #{fks}"
        if options.key?(:column) && options.key?(:to_table) && options[:to_table] != nil
          name = foreign_key_name(from_table, options)
          puts_log "foreign_key_for name = #{options}"
          fks.detect { |fk| fk.defined_for?(name: name) }
        else
          fks.detect { |fk| fk.defined_for?(**options) }
        end
      end

      def foreign_key_for!(from_table, to_table: nil, **options)
        puts_log "foreign_key_for! from_table = #{from_table}, to_table = #{to_table}, options = #{options}"
        foreign_key_for(from_table, to_table: to_table, **options) ||
          raise(ArgumentError, "Table '#{from_table}' has no foreign key for #{to_table || options}")
      end

      def foreign_key_exists?(from_table, to_table = nil, **options)
        puts_log "foreign_key_exists? from_table = #{from_table}, to_table = #{to_table}, options = #{options}"
        foreign_key_for(from_table, to_table: to_table, **options).present?
      end

      def remove_foreign_key(from_table, to_table = nil, **options)
        puts_log "remove_foreign_key from_table = #{from_table}, to_table = #{to_table}, options = #{options}"
        #to_table ||= options[:to_table]
        return unless use_foreign_keys?
        #return if options.delete(:if_exists) == true && !foreign_key_exists?(from_table, to_table, **options.slice(:column))
        return if options.delete(:if_exists) == true && !foreign_key_exists?(from_table, to_table)

        fk_name_to_delete = foreign_key_for!(from_table, to_table: to_table, **options).name
        puts_log "remove_foreign_key fk_name_to_delete = #{fk_name_to_delete}"

        at = create_alter_table from_table
        at.drop_foreign_key fk_name_to_delete

        execute schema_creation.accept(at)
      end

      def create_table_definition(name, **options)
        puts_log "create_table_definition name = #{name}"
        puts_log caller
        IBM_DBAdapter::TableDefinition.new(self, name, **options)
      end

      def create_alter_table(name)
        puts_log "create_alter_table name = #{name}"
        IBM_DBAdapter::AlterTable.new create_table_definition(name)
      end

      def assert_valid_deferrable(deferrable)
        return if !deferrable || %i(immediate deferred).include?(deferrable)

        raise ArgumentError, "deferrable must be `:immediate` or `:deferred`, got: `#{deferrable.inspect}`"
      end

      def remove_index(table_name, column_name = nil, **options)
        puts_log "remove_index table_name = #{table_name}, column_name = #{column_name}, options = #{options}"
        return if options[:if_exists] && !index_exists?(table_name, column_name, **options)

        execute("DROP INDEX #{index_name_for_remove(table_name, column_name, options)}")
      end

      def column_for(table_name, column_name)
        super
      end

      protected

      def initialize_type_map(m = type_map) # :nodoc:
        puts_log 'initialize_type_map'
        register_class_with_limit m, /boolean/i,   Type::Boolean
        register_class_with_limit m, /char/i,      Type::String
        register_class_with_limit m, /binary/i,    Type::Binary
        register_class_with_limit m, /text/i,      Type::Text
        register_class_with_precision m, /date/i,      Type::Date
        register_class_with_precision m, /time/i,      Type::Time
        register_class_with_precision m, /datetime/i,  Type::DateTime
        register_class_with_limit m, /float/i, Type::Float

        m.register_type(/^bigint/i,    Type::Integer.new(limit: 8))
        m.register_type(/^int/i,       Type::Integer.new(limit: 4))
        m.register_type(/^smallint/i,  Type::Integer.new(limit: 2))
        m.register_type(/^tinyint/i,   Type::Integer.new(limit: 1))

        m.alias_type(/blob/i,      'binary')
        m.alias_type(/clob/i,      'text')
        m.alias_type(/timestamp/i, 'datetime')
        m.alias_type(/numeric/i,   'decimal')
        m.alias_type(/number/i,    'decimal')
        m.alias_type(/double/i,    'float')

        m.register_type(/decimal/i) do |sql_type|
          scale = extract_scale(sql_type)
          precision = extract_precision(sql_type)

          if scale == 0
            # FIXME: Remove this class as well
            Type::DecimalWithoutScale.new(precision: precision)
          else
            Type::Decimal.new(precision: precision, scale: scale)
          end
        end

        m.alias_type(/xml/i, 'text')
        m.alias_type(/for bit data/i, 'binary')
        m.alias_type(/serial/i, 'int')
        m.alias_type(/decfloat/i, 'decimal')
        m.alias_type(/real/i, 'decimal')
        m.alias_type(/graphic/i, 'binary')
        m.alias_type(/rowid/i, 'int')
      end

      class SchemaDumper < ConnectionAdapters::SchemaDumper
        def dump(stream) # Like in abstract class, we no need to call header() & trailer().
          header(stream)
          extensions(stream)
          tables(stream)
          stream
        end
      end
    end # class IBM_DBAdapter

    # This class contains common code across DB's (DB2 LUW, zOS, i5 and IDS)
    class IBM_DataServer
      def initialize(adapter, ar3)
        @adapter = adapter
        @isAr3 = ar3
      end

      def last_generated_id(stmt); end

      def create_index_after_table(table_name, cloumn_name); end

      def setup_for_lob_table; end

      def reorg_table(table_name); end

      def check_reserved_words(col_name)
        @adapter.puts_log 'check_reserved_words'
        col_name.to_s
      end

      # This is supported by the DB2 for Linux, UNIX, Windows data servers
      # and by the DB2 for i5 data servers
      def remove_column(table_name, column_name)
        @adapter.puts_log 'remove_column'
        begin
          @adapter.execute "ALTER TABLE #{table_name} DROP #{column_name}"
          reorg_table(table_name)
        rescue StandardError => e
          # Provide details on the current XML columns support
          raise "#{e}" unless e.message.include?('SQLCODE=-1242') && e.message.include?('42997')

          raise StatementInvalid,
                "A column that is part of a table containing an XML column cannot be dropped. \
To remove the column, the table must be dropped and recreated without the #{column_name} column: #{e}"
        end
      end

      def select(stmt)
        @adapter.puts_log 'select'
        results = []
        # Fetches all the results available. IBM_DB.fetch_assoc(stmt) returns
        # an hash for each single record.
        # The loop stops when there aren't any more valid records to fetch
        begin
          if @isAr3
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
        rescue StandardError => e # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
          raise StatementInvalid, "Failed to retrieve data: #{error_msg}" if error_msg && !error_msg.empty?

          error_msg = 'An unexpected error occurred during data retrieval'
          error_msg += ": #{e.message}" unless e.message.empty?
          raise error_msg
        end
        results
      end

      def select_rows(_sql, _name, stmt, results)
        @adapter.puts_log 'select_rows'
        # Fetches all the results available. IBM_DB.fetch_array(stmt) returns
        # an array representing a row in a result set.
        # The loop stops when there aren't any more valid records to fetch
        begin
          while single_array = IBM_DB.fetch_array(stmt)
            # Add the array to results array
            results << single_array
          end
        rescue StandardError => e # Handle driver fetch errors
          error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
          raise StatementInvalid, "Failed to retrieve data: #{error_msg}" if error_msg && !error_msg.empty?

          error_msg = 'An unexpected error occurred during data retrieval'
          error_msg += ": #{e.message}" unless e.message.empty?
          raise error_msg
        end
        results
      end

      # Praveen
      def prepare(sql, _name = nil)
        @adapter.puts_log 'prepare'
        begin
          stmt = IBM_DB.prepare(@adapter.connection, sql)
          raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN) unless stmt

          stmt
        rescue StandardError => e
          raise "Failed to prepare sql #{sql} due to: #{e}" if e && !e.message.empty?

          raise 'An unexpected error occurred during SQLprepare'
        end
      end

      # Akhil Tcheck for if_exits added so that it will try to drop even if the table does not exit.
      def execute(sql, _name = nil)
        @adapter.puts_log "IBM_DataServer execute #{sql} #{Thread.current}"

        begin
          if @adapter.connection.nil? || @adapter.connection == false
            raise ActiveRecord::ConnectionNotEstablished, 'called on a closed database'
          elsif stmt = IBM_DB.exec(@adapter.connection, sql)
            stmt # Return the statement object
          else
            raise StatementInvalid, IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN), sql
          end
        rescue StandardError => e
          raise unless e && !e.message.empty?

          @adapter.puts_log "104 error = #{e.message}"
          @adapter.puts_log "104 sql = #{sql}"
          raise StatementInvalid
        end
      end

      def set_schema(schema)
        @adapter.puts_log 'set_schema'
        @adapter.execute("SET SCHEMA #{schema}")
      end

      def get_datetime_mapping; end

      def get_time_mapping; end

      def get_double_mapping; end

      def change_column_default(table_name, column_name, default); end

      def change_column_null(table_name, column_name, null, default); end

      def set_binary_default(value); end

      def set_binary_value; end

      def set_text_default; end

      def set_case(value); end

      def limit_not_supported_types
        %i[integer double date time timestamp xml bigint]
      end
    end # class IBM_DataServer

    class IBM_DB2 < IBM_DataServer
      def initialize(adapter, ar3)
        super(adapter, ar3)
        @limit = @offset = nil
      end

      def rename_column(_table_name, _column_name, _new_column_name)
        @adapter.puts_log 'rename_column'
        raise NotImplementedError, 'rename_column is not implemented yet in the IBM_DB Adapter'
      end

      def primary_key_definition(start_id)
        @adapter.puts_log 'primary_key_definition'
        "INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH #{start_id})"
      end

      # Returns the last automatically generated ID.
      # This method is required by the +insert+ method
      # The "stmt" parameter is ignored for DB2 but used for IDS
      def last_generated_id(stmt)
        # Queries the db to obtain the last ID that was automatically generated
        @adapter.puts_log 'last_generated_id'
        sql = 'SELECT IDENTITY_VAL_LOCAL() FROM SYSIBM.SYSDUMMY1'
        stmt = IBM_DB.prepare(@adapter.connection, sql)
        if stmt
          if IBM_DB.execute(stmt, nil)
            begin
              # Fetches the only record available (containing the last id)
              IBM_DB.fetch_row(stmt)
              # Retrieves and returns the result of the query with the last id.
              id_value = IBM_DB.result(stmt, 0)
              id_value.to_i
            rescue StandardError => e # Handle driver fetch errors
              error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
              raise "Failed to retrieve last generated id: #{error_msg}" if error_msg && !error_msg.empty?

              error_msg = 'An unexpected error occurred during retrieval of last generated id'
              error_msg += ": #{e.message}" unless e.message.empty?
              raise error_msg
            ensure # Free resources associated with the statement
              IBM_DB.free_stmt(stmt) if stmt
            end
          else
            error_msg = IBM_DB.getErrormsg(stmt, IBM_DB::DB_STMT)
            IBM_DB.free_stmt(stmt) if stmt
            raise "Failed to retrieve last generated id: #{error_msg}" if error_msg && !error_msg.empty?

            error_msg = 'An unexpected error occurred during retrieval of last generated id'
            raise error_msg

          end
        else
          error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN)
          raise "Failed to retrieve last generated id due to error: #{error_msg}" if error_msg && !error_msg.empty?

          raise StandardError.new('An unexpected error occurred during retrieval of last generated id')

        end
      end

      def change_column(table_name, column_name, type, options)
        @adapter.puts_log "change_column #{table_name}, #{column_name}, #{type}"
        column = @adapter.column_for(table_name, column_name)
        data_type = @adapter.type_to_sql(type, options[:limit], options[:precision], options[:scale])

        if column.sql_type != data_type
          begin
            execute "ALTER TABLE #{table_name} ALTER #{column_name} SET DATA TYPE #{data_type}"
          rescue StandardError => e
            raise "#{e}" unless e.message.include?('SQLCODE=-190')

            raise StatementInvalid,
                  "Please consult documentation for compatible data types while changing column datatype. \
               The column datatype change to [#{data_type}] is not supported by this data server: #{e}"
          end
          reorg_table(table_name)
        end

        change_column_default(table_name, column_name, options[:default]) if options.key?(:default)
        return unless options.key?(:null)

        change_column_null(table_name, column_name, options[:null], nil)
      end

      def extract_new_default_value(default_or_changes)
        @adapter.puts_log 'extract_new_default_value'
        if default_or_changes.is_a?(Hash) && default_or_changes.has_key?(:from) && default_or_changes.has_key?(:to)
          default_or_changes[:to]
        else
          default_or_changes
        end
      end

      # DB2 specific ALTER TABLE statement to add a default clause
      def change_column_default(table_name, column_name, default)
        @adapter.puts_log "change_column_default #{table_name} #{column_name}"
        @adapter.puts_log "Default: #{default}"

        default = extract_new_default_value(default)
        # SQL statement which alters column's default value
        change_column_sql = if default.nil?
                              "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET WITH DEFAULT NULL"
                            else
                              "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET WITH DEFAULT #{@adapter.quote(default)}"
                            end

        stmt = execute(change_column_sql)
        reorg_table(table_name)
      ensure
        IBM_DB.free_stmt(stmt) if stmt
      end

      # DB2 specific ALTER TABLE statement to change the nullability of a column
      def change_column_null(table_name, column_name, null, default)
        @adapter.puts_log "change_column_null #{table_name} #{column_name}"
        change_column_default(table_name, column_name, default) unless default.nil?

        unless null.nil?
          change_column_sql = if null
                                "ALTER TABLE #{table_name} ALTER #{column_name} DROP NOT NULL"
                              else
                                "ALTER TABLE #{table_name} ALTER #{column_name} SET NOT NULL"
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
        @adapter.puts_log 'get_datetime_mapping'
        'timestamp'
      end

      # This method returns the DB2 SQL type corresponding to the Rails
      # time type
      def get_time_mapping
        @adapter.puts_log 'get_time_mapping'
        'time'
      end

      # This method returns the DB2 SQL type corresponding to Rails double type
      def get_double_mapping
        @adapter.puts_log 'get_double_mapping'
        'double'
      end

      # This method generates the default blob value specified for
      # DB2 Dataservers
      def set_binary_default(value)
        @adapter.puts_log 'set_binary_default'
        "BLOB('#{value}')"
      end

      # This method generates the blob value specified for DB2 Dataservers
      def set_binary_value
        @adapter.puts_log 'set_binary_value'
        "BLOB('?')"
      end

      # This method generates the default clob value specified for
      # DB2 Dataservers
      def set_text_default(value)
        @adapter.puts_log 'set_text_default'
        "'#{value}'"
      end

      # For DB2 Dataservers , the arguments to the meta-data functions
      # need to be in upper-case
      def set_case(value)
        @adapter.puts_log 'set_case'
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
        %i[integer double date time xml bigint]
      end

      # Alter table column for renaming a column
      # This feature is supported for against DB2 V97 and above only
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        unless nil_condition
          empty_condition = _table_name.empty? ||
                            _column_name.empty? ||
                            _new_column_name.empty?
        end

        if nil_condition || empty_condition
          raise ArgumentError, 'One of the arguments passed to rename_column is empty or nil'
        end

        begin
          rename_column_sql = "ALTER TABLE #{_table_name} RENAME COLUMN #{_column_name} \
                   TO #{_new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN)
            raise "Rename column failed : #{error_msg}" if error_msg && !error_msg.empty?

            raise StandardError.new('An unexpected error occurred during renaming the column')

          end

          reorg_table(_table_name)
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end # End of begin
      end # End of rename_column
    end # IBM_DB2_LUW_COBRA

    module HostedDataServer
      require 'pathname'
      # find DB2-i5-zOS rezerved words file relative path
      rfile = Pathname.new(File.dirname(__FILE__)).parent + 'vendor' + 'db2-i5-zOS.yaml'
      raise "Failed to locate IBM_DB Adapter dependency: #{rfile}" unless rfile

      RESERVED_WORDS = open(rfile.to_s) { |f| YAML.load(f) }
      def check_reserved_words(col_name)
        puts_log '164'
        if RESERVED_WORDS[col_name]
          '"' + RESERVED_WORDS[col_name] + '"'
        else
          col_name.to_s
        end
      end
    end # module HostedDataServer

    class IBM_DB2_ZOS < IBM_DB2
      # since v9 doesn't need, suggest putting it in HostedDataServer?
      def create_index_after_table(table_name, column_name)
        @adapter.add_index(table_name, column_name, unique: true)
      end

      def remove_column(table_name, column_name)
        raise NotImplementedError,
              'remove_column is not supported by the DB2 for zOS data server'
      end

      # Alter table column for renaming a column
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        unless nil_condition
          empty_condition = _table_name.empty? ||
                            _column_name.empty? ||
                            _new_column_name.empty?
        end

        if nil_condition || empty_condition
          raise ArgumentError, 'One of the arguments passed to rename_column is empty or nil'
        end

        begin
          rename_column_sql = "ALTER TABLE #{_table_name} RENAME COLUMN #{_column_name} \
                   TO #{_new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN)
            raise "Rename column failed : #{error_msg}" if error_msg && !error_msg.empty?

            raise StandardError.new('An unexpected error occurred during renaming the column')

          end

          reorg_table(_table_name)
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end # End of begin
      end # End of rename_column

      # DB2 z/OS only allows NULL or "" (empty) string as DEFAULT value for a BLOB column.
      # For non-empty string and non-NULL values, the server returns error
      def set_binary_default(value)
        "#{value}"
      end

      def change_column_default(table_name, column_name, default)
        if default
          super
        else
          raise NotImplementedError,
                'DB2 for zOS data server version 9 does not support changing the column default to NULL'
        end
      end

      def change_column_null(table_name, column_name, null, default)
        raise NotImplementedError,
              "DB2 for zOS data server does not support changing the column's nullability"
      end
    end # class IBM_DB2_ZOS

    class IBM_DB2_ZOS_8 < IBM_DB2_ZOS
      include HostedDataServer

      # This call is needed on DB2 z/OS v8 for the creation of tables
      # with LOBs.  When issued, this call does the following:
      #   DB2 creates LOB table spaces, auxiliary tables, and indexes on auxiliary
      #   tables for LOB columns.
      def setup_for_lob_table
        execute "SET CURRENT RULES = 'STD'"
      end

      def rename_column(table_name, column_name, new_column_name)
        raise NotImplementedError, 'rename_column is not implemented for DB2 on zOS 8'
      end

      def change_column_default(table_name, column_name, default)
        raise NotImplementedError,
              'DB2 for zOS data server version 8 does not support changing the column default'
      end
    end # class IBM_DB2_ZOS_8

    class IBM_DB2_I5 < IBM_DB2
      include HostedDataServer
    end # class IBM_DB2_I5

    class IBM_IDS < IBM_DataServer
      # IDS does not support the SET SCHEMA syntax
      def set_schema(schema); end

      # IDS specific ALTER TABLE statement to rename a column
      def rename_column(table_name, column_name, new_column_name)
        _table_name      = table_name.to_s
        _column_name     = column_name.to_s
        _new_column_name = new_column_name.to_s

        nil_condition    = _table_name.nil? || _column_name.nil? || _new_column_name.nil?
        unless nil_condition
          empty_condition = _table_name.empty? ||
                            _column_name.empty? ||
                            _new_column_name.empty?
        end

        if nil_condition || empty_condition
          raise ArgumentError, 'One of the arguments passed to rename_column is empty or nil'
        end

        begin
          rename_column_sql = "RENAME COLUMN #{table_name}.#{column_name} TO \
               #{new_column_name}"

          unless stmt = execute(rename_column_sql)
            error_msg = IBM_DB.getErrormsg(@adapter.connection, IBM_DB::DB_CONN)
            raise "Rename column failed : #{error_msg}" if error_msg && !error_msg.empty?

            raise StandardError.new('An unexpected error occurred during renaming the column')

          end

          reorg_table(_table_name)
        ensure
          IBM_DB.free_stmt(stmt) if stmt
        end # End of begin
      end # End of rename_column

      def primary_key_definition(start_id)
        "SERIAL(#{start_id})"
      end

      def change_column(table_name, column_name, type, options)
        if !options[:null].nil? && !options[:null]
          execute "ALTER TABLE #{table_name} MODIFY #{column_name} #{@adapter.type_to_sql(type, options[:limit],
                                                                                          options[:precision], options[:scale])} NOT NULL"
        else
          execute "ALTER TABLE #{table_name} MODIFY #{column_name} #{@adapter.type_to_sql(type, options[:limit],
                                                                                          options[:precision], options[:scale])}"
        end
        change_column_default(table_name, column_name, options[:default]) unless options[:default].nil?
        reorg_table(table_name)
      end

      # IDS specific ALTER TABLE statement to add a default clause
      # IDS requires the data type to be explicitly specified when adding the
      # DEFAULT clause
      def change_column_default(table_name, column_name, default)
        sql_type = nil
        is_nullable = true
        @adapter.columns(table_name).select do |col|
          if col.name == column_name
            sql_type = @adapter.type_to_sql(col.sql_type, col.limit, col.precision, col.scale)
            is_nullable = col.null
          end
        end
        # SQL statement which alters column's default value
        change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type} DEFAULT #{@adapter.quote(default)}"
        change_column_sql << ' NOT NULL' unless is_nullable
        stmt = execute(change_column_sql)
        reorg_table(table_name)
      # Ensures to free the resources associated with the statement
      ensure
        IBM_DB.free_stmt(stmt) if stmt
      end

      # IDS specific ALTER TABLE statement to change the nullability of a column
      def change_column_null(table_name, column_name, null, default)
        change_column_default table_name, column_name, default unless default.nil?
        sql_type = nil
        @adapter.columns(table_name).select do |col|
          sql_type = @adapter.type_to_sql(col.sql_type, col.limit, col.precision, col.scale) if col.name == column_name
        end
        unless null.nil?
          change_column_sql = if !null
                                "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type} NOT NULL"
                              else
                                "ALTER TABLE #{table_name} MODIFY #{column_name} #{sql_type}"
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
        'datetime year to fraction(5)'
      end

      # This method returns the IDS SQL type corresponding to the Rails
      # time type
      def get_time_mapping
        'datetime hour to second'
      end

      # This method returns the IDS SQL type corresponding to Rails double type
      def get_double_mapping
        'double precision'
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
        return if value == 'NULL'

        raise 'Informix Dynamic Server only allows NULL as a valid default value for a BLOB data type'
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
        return if value == 'NULL'

        raise 'Informix Dynamic Server only allows NULL as a valid default value for a CLOB data type'
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
  # Check Arel version
  begin
    arelVersion = Arel::VERSION.to_i
  rescue StandardError
    arelVersion = 0
  end
  if arelVersion >= 6
    module Collectors
      class Bind
        def changeFirstSegment(segment)
          @parts[0] = segment
        end

        def changeEndSegment(segment)
          len = @parts.length
          @parts[len] = segment
        end
      end
    end
  end

  module Visitors
    class Visitor # opening and closing the class to ensure backward compatibility
    end

    # Check Arel version
    begin
      arelVersion = Arel::VERSION.to_i
    rescue StandardError
      arelVersion = 0
    end

    if arelVersion >= 6 && arelVersion <= 9
      class ToSql < Arel::Visitors::Reduce # opening and closing the class to ensure backward compatibility
        # In case when using Rails-2.3.x there is no arel used due to which the constructor has to be defined explicitly
        # to ensure the same code works on any version of Rails

        # Check Arel version
        begin
          @arelVersion = Arel::VERSION.to_i
        rescue StandardError
          @arelVersion = 0
        end

        if @arelVersion >= 3
          def initialize(connection)
            super()
            @connection     = connection
            @schema_cache   = connection.schema_cache if connection.respond_to?(:schema_cache)
            @quoted_tables  = {}
            @quoted_columns = {}
            @last_column    = nil
          end
        end
      end
    else
      class ToSql < Arel::Visitors::Visitor # opening and closing the class to ensure backward compatibility
        # In case when using Rails-2.3.x there is no arel used due to which the constructor has to be defined explicitly
        # to ensure the same code works on any version of Rails

        # Check Arel version
        begin
          @arelVersion = Arel::VERSION.to_i
        rescue StandardError
          @arelVersion = 0
        end
        if @arelVersion >= 3
          def initialize(connection)
            super()
            @connection     = connection
            @schema_cache   = connection.schema_cache if connection.respond_to?(:schema_cache)
            @quoted_tables  = {}
            @quoted_columns = {}
            @last_column    = nil
          end
        end
      end
    end

    class IBM_DB < Arel::Visitors::ToSql
      private

      def visit_Arel_Nodes_Limit(o, collector)
        collector << ' LIMIT '
        visit o.expr, collector
      end

      def visit_Arel_Nodes_Offset(o, collector)
        @connection.puts_log "visit_Arel_Nodes_Offset #{@connection.servertype}"
        if !@connection.servertype.instance_of? ActiveRecord::ConnectionAdapters::IBM_IDS
          collector << ' OFFSET '
          visit o.expr, collector
        end
      end

      def visit_Arel_Nodes_ValuesList(o, collector)
        collector << 'VALUES '
        o.rows.each_with_index do |row, i|
          collector << ', ' unless i == 0
          collector << '('
          row.each_with_index do |value, k|
            collector << ', ' unless k == 0
            case value
            when Nodes::SqlLiteral, Nodes::BindParam, ActiveModel::Attribute
              collector = visit(value, collector)
            # collector << quote(value).to_s
            else
              collector << quote(value).to_s
            end
          end
          collector << ')'
        end
        collector
      end

      def visit_Arel_Nodes_SelectStatement(o, collector)
        @connection.puts_log "visit_Arel_Nodes_SelectStatement #{@connection.servertype}"
        if o.with
          collector = visit o.with, collector
          collector << ' '
        end

        collector = o.cores.inject(collector) do |c, x|
          visit_Arel_Nodes_SelectCore(x, c)
        end

        unless o.orders.empty?
          collector << ' ORDER BY '
          len = o.orders.length - 1
          o.orders.each_with_index do |x, i|
            collector = visit(x, collector)
            collector << ', ' unless len == i
          end
        end

        if o.offset && o.limit
          visit_Arel_Nodes_Limit(o.limit, collector)
          visit_Arel_Nodes_Offset(o.offset, collector)
        elsif o.offset && o.limit.nil?
          if !@connection.servertype.instance_of? ActiveRecord::ConnectionAdapters::IBM_IDS
            collector << ' OFFSET '
            visit o.offset.expr, collector
            collector << ' ROWS '
            maybe_visit o.lock, collector
          end
        else
          visit_Arel_Nodes_SelectOptions(o, collector)
        end
      end

      # Locks are not supported in SQLite
      def visit_Arel_Nodes_Lock(_o, collector)
        collector
      end
    end
  end
end
