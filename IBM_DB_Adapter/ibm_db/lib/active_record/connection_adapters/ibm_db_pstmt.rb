# +-----------------------------------------------------------------------+
# |                                                                       |
# | Copyright (c) 2004-2009 David Heinemeier Hansson                      |
# | Copyright (c) 2010 IBM Corporation (modifications)                    |
# |                                                                       |
# | Permission is hereby granted, free of charge, to any person obtaining |
# | a copy of this software and associated documentation files (the       |
# | "Software"), to deal in the Software without restriction, including   |
# | without limitation the rights to use, copy, modify, merge, publish,   |
# | distribute, sublicense, and/or sell copies of the Software, and to    |
# | permit persons to whom the Software is furnished to do so, subject to |
# | the following conditions:                                             |
#                                                                         |
# | The above copyright notice and this permission notice shall be        |
# | included in all copies or substantial portions of the Software.       |
# |                                                                       |
# | THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       |
# | EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    |
# | MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.|
# | IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR      |
# | ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION           |
# | OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION |
# | WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.       |
# |                                                                       |
# +-----------------------------------------------------------------------+

module ActiveRecord
  class Base

    def quote_value(value, column = nil) #:nodoc:
      connection.quote_value_for_pstmt(value,column)
    end

    # Deletes the record in the database and freezes this instance to reflect that no changes should
    # be made (since they can't be persisted).
    def destroy_without_lock
      unless new_record?
        # Prepare the sql for deleting a row
        pstmt = connection.prepare(
                  "DELETE FROM #{self.class.quoted_table_name} " +
                  "WHERE #{connection.quote_column_name(self.class.primary_key)} = ?",
                  "#{self.class.name} Destroy"
                )
        # Execute the prepared Statement
        connection.prepared_delete(pstmt, [connection.quote_value_for_pstmt(quoted_id)])
      end

      @destroyed = true
      freeze
    end

    def update_without_lock(attribute_names = @attributes.keys)
      quoted_attributes = attributes_with_quotes(false, false, attribute_names)
      return 0 if quoted_attributes.empty?

      columns_values_hash = quoted_comma_pair_list(connection, quoted_attributes)
      pstmt = connection.prepare(
        "UPDATE #{self.class.quoted_table_name} " +
        "SET #{columns_values_hash["sqlSegment"]} " +
        "WHERE #{connection.quote_column_name(self.class.primary_key)} = ?",
        "#{self.class.name} Update"
      )
      columns_values_hash["paramArray"] << connection.quote_value_for_pstmt(id)
      connection.prepared_update(pstmt, columns_values_hash["paramArray"] )
    end

    def attributes_with_quotes(include_primary_key = true, include_readonly_attributes = true, attribute_names = @attributes.keys)
      quoted = {}
      connection = self.class.connection
      attribute_names.each do |name|
        if (column = column_for_attribute(name)) && (include_primary_key || !column.primary)
          value = read_attribute(name)

          # We need explicit to_yaml because quote() does not properly convert Time/Date fields to YAML.
          if value && self.class.serialized_attributes.has_key?(name) && (value.acts_like?(:date) || value.acts_like?(:time))
            value = value.to_yaml
          end

            quoted[name] = connection.quote_value_for_pstmt(value)
        end
      end

      include_readonly_attributes ? quoted : remove_readonly_attributes(quoted)
    end

    def comma_pair_list(hash)
      return_hash = {}
      return_hash["paramArray"] = []

      return_hash["sqlSegment"] = hash.inject([]) { |list, pair| 
         return_hash["paramArray"] << pair.last 
		 list << "#{pair.first} = ? " 
      }.join(", ")
      return_hash
    end

    def update_without_dirty(attribute_names = @attributes.keys) #:nodoc:
      return update_without_lock(attribute_names) unless locking_enabled?
      return 0 if attribute_names.empty?

      lock_col = self.class.locking_column
      previous_value = send(lock_col).to_i
      send(lock_col + '=', previous_value + 1)

      attribute_names += [lock_col]
      attribute_names.uniq!

      columns_values_hash = quoted_comma_pair_list(connection, attributes_with_quotes(false, false, attribute_names))
      begin
        pstmt = connection.prepare(<<-end_sql, "#{self.class.name} Update with optimistic locking")
          UPDATE #{self.class.quoted_table_name}
          SET #{columns_values_hash["sqlSegment"]}
          WHERE #{self.class.primary_key} = ?
          AND #{self.class.quoted_locking_column} = ?
        end_sql

        columns_values_hash["paramArray"] << connection.quote_value_for_pstmt(id)
        columns_values_hash["paramArray"] << connection.quote_value_for_pstmt(previous_value)

        affected_rows = connection.prepared_update(pstmt, columns_values_hash["paramArray"])
        unless affected_rows == 1
          raise ActiveRecord::StaleObjectError, "Attempted to update a stale object"
        end

        affected_rows

      # If something went wrong, revert the version.
      rescue Exception
        send(lock_col + '=', previous_value)
        raise
      end
    end

    def destroy_without_callbacks #:nodoc:
      return destroy_without_lock unless locking_enabled?

      paramArray = []

      unless new_record?
        lock_col = self.class.locking_column
        previous_value = send(lock_col).to_i

        pstmt = connection.prepare(
          "DELETE FROM #{self.class.quoted_table_name} " +
          "WHERE #{connection.quote_column_name(self.class.primary_key)} = ? " +
                "AND #{self.class.quoted_locking_column} = ?",
          "#{self.class.name} Destroy"
        )

        paramArray << connection.quote_value_for_pstmt(quoted_id)
        paramArray << connection.quote_value_for_pstmt(previous_value)

        affected_rows = connection.prepared_delete(pstmt, paramArray)

        unless affected_rows == 1
          raise ActiveRecord::StaleObjectError, "Attempted to delete a stale object"
        end
      end

      freeze
    end

    def create_without_timestamps
      if self.id.nil? && connection.prefetch_primary_key?(self.class.table_name)
        self.id = connection.next_sequence_value(self.class.sequence_name)
      end

      quoted_attributes = attributes_with_quotes

      statement = if quoted_attributes.empty?
        connection.empty_insert_statement(self.class.table_name)
      else
        param_marker_sql_segment = quoted_attributes.values.map{|value| '?'}.join(', ')
        "INSERT INTO #{self.class.quoted_table_name} " +
        "(#{quoted_column_names.join(', ')}) " +
        "VALUES(#{param_marker_sql_segment})"
      end

      pstmt = connection.prepare(statement, "#{self.class.name} Create")
      self.id = connection.prepared_insert(pstmt, quoted_attributes.values, self.id)

      @new_record = false
      id
    end

    private :update_without_lock, :attributes_with_quotes, :comma_pair_list
    private :update_without_dirty, :destroy_without_callbacks
    private :create_without_timestamps

    class << self

      def validates_uniqueness_of(*attr_names)
        configuration = { :case_sensitive => true }
        configuration.update(attr_names.extract_options!)

        validates_each(attr_names,configuration) do |record, attr_name, value|
          # The check for an existing value should be run from a class that
          # isn't abstract. This means working down from the current class
          # (self), to the first non-abstract class. Since classes don't know
          # their subclasses, we have to build the hierarchy between self and
          # the record's class.
          class_hierarchy = [record.class]
          while class_hierarchy.first != self
            class_hierarchy.insert(0, class_hierarchy.first.superclass)
          end

          # Now we can work our way down the tree to the first non-abstract
          # class (which has a database table to query from).
                    finder_class = class_hierarchy.detect { |klass| !klass.abstract_class? }

          column = finder_class.columns_hash[attr_name.to_s]

          if value.nil?
            comparison_operator = "IS NULL"
          elsif column.text?
            comparison_operator = "#{connection.case_sensitive_equality_operator} ?"
            value = column.limit ? value.to_s.mb_chars[0, column.limit] : value.to_s
          else
            comparison_operator = "= ?"
          end

          sql_attribute = "#{record.class.quoted_table_name}.#{connection.quote_column_name(attr_name)}"

          if value.nil? || (configuration[:case_sensitive] || !column.text?)
            condition_sql = "#{sql_attribute} #{comparison_operator}"
            condition_params = [value] if(!value.nil?) #Add the value only if not nil, because in case of nil comparison op is IS NULL
          else
            condition_sql = "LOWER(#{sql_attribute}) #{comparison_operator}"
            condition_params = [value.mb_chars.downcase]
          end

          if scope = configuration[:scope]
            Array(scope).map do |scope_item|
              scope_value = record.send(scope_item)
              condition_sql << " AND " << attribute_condition("#{record.class.quoted_table_name}.#{scope_item}", scope_value)
              condition_params << scope_value
            end
          end

          unless record.new_record?
            condition_sql << " AND #{record.class.quoted_table_name}.#{record.class.primary_key} <> ?"
            condition_params << record.send(:id)
          end

          finder_class.with_exclusive_scope do
            if finder_class.exists?([condition_sql, *condition_params])
              record.errors.add(attr_name, :taken, :default => configuration[:message], :value => value)
            end
          end
        end
      end

      def find_one(id, options)
        param_array = [quote_value(id,columns_hash[primary_key])]
        if options[:conditions]
          sql_param_hash = sanitize_sql(options[:conditions])
          conditions = " AND (#{sql_param_hash["sqlSegment"]})"
          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
        end

        options.update :conditions => ["#{quoted_table_name}.#{connection.quote_column_name(primary_key)} = ?#{conditions}"] + param_array

        # Use find_every(options).first since the primary key condition
        # already ensures we have a single record. Using find_initial adds
        # a superfluous :limit => 1.
        if result = find_every(options).first
          result
        else
          raise RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions} with parameters #{param_array.last(param_array.size-1)}"
        end
      end

      def find_some(ids, options)
        param_array = []
        ids_array = ids.map { |id| quote_value(id,columns_hash[primary_key]) }
        if options[:conditions]
          sql_param_hash = sanitize_sql(options[:conditions])
          conditions = " AND (#{sql_param_hash["sqlSegment"]})"
          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
        end

        options.update :conditions => ["#{quoted_table_name}.#{connection.quote_column_name(primary_key)} IN (?)#{conditions}"] + [ids_array] + param_array

        result = find_every(options)

        # Determine expected size from limit and offset, not just ids.size.
        expected_size =
          if options[:limit] && ids.size > options[:limit]
            options[:limit]
          else
            ids.size
          end

        # 11 ids with limit 3, offset 9 should give 2 results.
        if options[:offset] && (ids.size - options[:offset] < expected_size)
          expected_size = ids.size - options[:offset]
        end

        if result.size == expected_size
          result
        else
          raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids.join(', ')})#{conditions} with parameter(s) #{param_array.join(', ')} (found #{result.size} results, but was looking for #{expected_size})"
        end
      end

      def merge_joins(*joins)
        sql_param_hash = {}
        param_array = []
        if joins.any?{|j| j.is_a?(String) || array_of_strings?(j) || (j.is_a?(Hash) && j.has_key?("pstmt_hook"))}
          joins_array = []
          joins_compare_array = []

          joins.each do |join|
            get_join_associations = true
            if join.is_a?(String)
              unless joins_compare_array.include?(join)
                joins_array << join
                joins_compare_array << join
              end
              get_join_associations = false
            elsif (join.is_a?(Hash) && join.has_key?("pstmt_hook"))
              if(join["pstmt_hook"]["sqlSegment"].is_a?(Array))
                compare_string = join["pstmt_hook"]["sqlSegment"].join(" ") + join["pstmt_hook"]["paramArray"].join(" ")
              else
                compare_string = join["pstmt_hook"]["sqlSegment"] + join["pstmt_hook"]["paramArray"].join(" ")
              end
              unless joins_compare_array.include?(compare_string)
                param_array = param_array + join["pstmt_hook"]["paramArray"] unless join["pstmt_hook"]["paramArray"].nil?
                joins_array << join["pstmt_hook"]["sqlSegment"]
                joins_compare_array << compare_string
              end
              get_join_associations = false
            end
            unless array_of_strings?(join)
              if get_join_associations
                join_dependency = ActiveRecord::Associations::ClassMethods::InnerJoinDependency.new(self, join, nil)
                join_dependency.join_associations.each do |assoc| 
                  sql_param_hash = assoc.association_join
                  compare_string = nil
                  compare_string = sql_param_hash["sqlSegment"] + sql_param_hash["paramArray"].join(" ") unless sql_param_hash.nil?
                  unless compare_string.nil? || joins_array.include?(compare_string)
                    param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
                    joins_array << sql_param_hash["sqlSegment"]
                    joins_compare_array << compare_string
                  end
                end
              end
            else
              if get_join_associations
                joins_array = joins_array + join.flatten.map{|j| j.strip }.uniq
              end
            end
          end
          sql_param_hash["sqlSegment"] = joins_array.flatten.map{|j| j.strip }.uniq
          sql_param_hash["paramArray"] = param_array
          {"pstmt_hook" => sql_param_hash}
        else
          sql_param_hash["sqlSegment"] = joins.collect{|j| safe_to_array(j)}.flatten.uniq
          sql_param_hash["paramArray"] = param_array
          {"pstmt_hook" => sql_param_hash}
        end
      end
		
      private :find_one, :find_some, :merge_joins

      def find_by_sql(sql)
        sql_param_hash = sanitize_sql(sql)
        connection.prepared_select(sql_param_hash, "#{name} Load").collect! { |record| instantiate(record) }
      end

      # Interpret Array and Hash as conditions and anything else as an id.
      def expand_id_conditions(id_or_conditions)
        case id_or_conditions
          when Array, Hash then id_or_conditions
          else {primary_key => id_or_conditions}
        end
      end

      def construct_finder_sql(options)
        param_array = []
        scope = scope(:find)
        sql  = "SELECT #{options[:select] || (scope && scope[:select]) || default_select(options[:joins] || (scope && scope[:joins]))} "
        sql << "FROM #{options[:from]  || (scope && scope[:from]) || quoted_table_name} "

        param_array = add_joins!(sql, options[:joins], scope)

        param_array = param_array + add_conditions!(sql, options[:conditions], scope)

        param_array = param_array + add_group!(sql, options[:group], options[:having], scope)

        add_order!(sql, options[:order], scope)

        temp_options = options.dup # Ensure that the necessary parameters are received in the duplicate, so that the original hash is intact
        temp_options[:paramArray] = [] # To receive the values for limit and offset.
        add_limit!(sql, temp_options, scope)

        param_array = param_array + temp_options[:paramArray]

        add_lock!(sql, options, scope)

        [sql] + param_array
      end

      def add_group!(sql, group, having, scope = :auto)
        param_array = []
        if group
          sql << " GROUP BY #{group}"
          if having
            sql_param_hash = sanitize_sql_for_conditions(having)
            sql << " HAVING #{sql_param_hash["sqlSegment"]}"
            param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
          end
        else
          scope = scope(:find) if :auto == scope
          if scope && (scoped_group = scope[:group])
            sql << " GROUP BY #{scoped_group}"
            if scope[:having]
              sql_param_hash = sanitize_sql_for_conditions(scope[:having])
              sql << " HAVING #{sql_param_hash["sqlSegment"]}"
              param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
            end
          end
        end
        param_array
      end

      # The optional scope argument is for the current <tt>:find</tt> scope.
      def add_joins!(sql, joins, scope = :auto)
        param_array = []
        scope = scope(:find) if :auto == scope

        if joins.is_a?(Hash) && joins.has_key?("pstmt_hook")
          param_array = joins["pstmt_hook"]["paramArray"]
          joins = joins["pstmt_hook"]["sqlSegment"]
        end

        merged_joins = if scope && scope[:joins] && joins 
                         join_merge_hash = merge_joins(scope[:joins], joins)
                         param_array = param_array + join_merge_hash["pstmt_hook"]["paramArray"]
                         join_merge_hash["pstmt_hook"]["sqlSegment"]
                       else
                         if(scope && scope[:joins].is_a?(Hash) && scope[:joins].has_key?("pstmt_hook"))
                           param_array = scope[:joins]["pstmt_hook"]["paramArray"]
                           (joins || scope[:joins]["pstmt_hook"]["sqlSegment"])
                         else
                           (joins || scope && scope[:joins])
                         end
                       end

        case merged_joins
        when Symbol, Hash, Array
          if array_of_strings?(merged_joins)
            sql << merged_joins.join(' ') + " "
          else
            join_dependency = ActiveRecord::Associations::ClassMethods::InnerJoinDependency.new(self, merged_joins, nil)
            sql << " #{join_dependency.join_associations.collect { |assoc| 
                          sql_param_hash = assoc.association_join 
                          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
                          sql_param_hash["sqlSegment"]
                        }.join} "
          end
        when String
          sql << " #{merged_joins} "
        end
        param_array
      end
      private :construct_finder_sql, :expand_id_conditions, :add_joins!, :add_group!

      def with_scope(method_scoping = {}, action = :merge, &block)
        method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

        # Dup first and second level of hash (method and params).
        method_scoping = method_scoping.inject({}) do |hash, (method, params)|
          hash[method] = (params == true) ? params : params.dup
          hash
        end

        method_scoping.assert_valid_keys([ :find, :create ])

        if f = method_scoping[:find]
          f.assert_valid_keys(VALID_FIND_OPTIONS)
          set_readonly_option! f
        end

        # Merge scopings
        if [:merge, :reverse_merge].include?(action) && current_scoped_methods
          method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
            case hash[method]
              when Hash
                if method == :find
                  (hash[method].keys + params.keys).uniq.each do |key|
                    merge = hash[method][key] && params[key] # merge if both scopes have the same key
                    if key == :conditions && merge
                      if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                        sql_param_hash    = merge_conditions(hash[method][key].deep_merge(params[key]))
                        hash[method][key] = [sql_param_hash["sqlSegment"]] + sql_param_hash["paramArray"]
                      else
                        sql_param_hash    = merge_conditions(params[key], hash[method][key])
                        hash[method][key] = [sql_param_hash["sqlSegment"]] + sql_param_hash["paramArray"]
                      end
                    elsif key == :include && merge
                      hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                    elsif key == :joins && merge
                      hash[method][key] = merge_joins(params[key], hash[method][key])
                    else
                      hash[method][key] = hash[method][key] || params[key]
                    end
                  end
                else
                  if action == :reverse_merge
                    hash[method] = hash[method].merge(params)
                  else
                    hash[method] = params.merge(hash[method])
                  end
                end
              else
                hash[method] = params
            end
            hash
          end
        end

        self.scoped_methods << method_scoping
        begin
          yield
        ensure
          self.scoped_methods.pop
        end
      end
      protected :with_scope

      def count_by_sql(sql)
        sql_param_hash = sanitize_conditions(sql)
        result = connection.prepared_select(sql_param_hash, "#{name} Count").first
        #result will be of type Hash.
        if result
          return result.values.first.to_i  #Retrieve the first value from hash
        else
          return 0
        end
      end

      def quote_value(value, column = nil) #:nodoc:
        connection.quote_value_for_pstmt(value,column)
      end

      def update_all(updates, conditions = nil, options = {})
        sql_values_hash = sanitize_sql_for_assignment(updates)
        param_array = sql_values_hash["paramArray"]

        sql  = "UPDATE #{quoted_table_name} SET #{sql_values_hash["sqlSegment"]} "

        scope = scope(:find)

        select_sql = ""
        temp_param_array = add_conditions!(select_sql, conditions, scope)

        if !param_array.nil? && !param_array.empty?
          param_array += temp_param_array
        else
          param_array = temp_param_array
        end

        if options.has_key?(:limit) || (scope && scope[:limit])
          # Only take order from scope if limit is also provided by scope, this
          # is useful for updating a has_many association with a limit.
          add_order!(select_sql, options[:order], scope)

          temp_options = options.dup # Ensure that the necessary parameters are received in the duplicate, so that the original hash is intact
          temp_options[:paramArray] = [] # To receive the values for limit and offset.
          add_limit!(select_sql, temp_options, scope)
          param_array = param_array + temp_options[:paramArray]

          sql.concat(connection.limited_update_conditions(select_sql, quoted_table_name, connection.quote_column_name(primary_key)))
        else
          add_order!(select_sql, options[:order], nil)
          sql.concat(select_sql)
        end

        pstmt = connection.prepare(sql, "#{name} Update")
        connection.prepared_update(pstmt, param_array)
      end

      def update_counters_without_lock(id, counters)
        updates = counters.inject([]) { |list, (counter_name, increment)|
          sign = increment < 0 ? "-" : "+"
          list << "#{connection.quote_column_name(counter_name)} = COALESCE(#{connection.quote_column_name(counter_name)}, 0) #{sign} #{increment.abs}"
        }.join(", ")

        if id.is_a?(Array)
          ids_list = id.map {|i|
            connection.quote_value_for_pstmt(i)
          }
          condition = ["#{connection.quote_column_name(primary_key)} IN  (?)", ids_list]
        else
          param_value = connection.quote_value_for_pstmt(id)
          condition = ["#{connection.quote_column_name(primary_key)} = ?", param_value]
        end

        update_all(updates, condition)
      end

      def delete_all(conditions = nil)
        sql = "DELETE FROM #{quoted_table_name} "
        param_array = add_conditions!(sql, conditions, scope(:find))
        # Prepare the sql for deleting the rows
        pstmt = connection.prepare(sql, "#{name} Delete all")
        # Execute the prepared Statement
        connection.prepared_delete(pstmt, param_array)
      end

      # Merges conditions so that the result is a valid +condition+
      def merge_conditions(*conditions)
        segments = []
        return_hash = {}
        return_hash["paramArray"] = []
        conditions.each do |condition|
          unless condition.blank?
            sql_param_hash = sanitize_sql(condition)
            unless sql_param_hash["sqlSegment"].blank?
              segments << sql_param_hash["sqlSegment"]
              if !sql_param_hash["paramArray"].nil? && !sql_param_hash["paramArray"].empty?
                return_hash["paramArray"] = return_hash["paramArray"] + 
                                            sql_param_hash["paramArray"]
              end
            end
          end
        end

        return_hash["sqlSegment"] = "(#{segments.join(') AND (')})" unless segments.empty?
        return_hash
      end

      # Adds a sanitized version of +conditions+ to the +sql+ string. Note that the passed-in +sql+ string is changed.
      # The optional scope argument is for the current <tt>:find</tt> scope.
      def add_conditions!(sql, conditions, scope = :auto)
        scope = scope(:find) if :auto == scope
        conditions = [conditions]
        conditions << scope[:conditions] if scope
        conditions << type_condition if finder_needs_type_condition?
        merged_conditions = merge_conditions(*conditions)
        sql << "WHERE #{merged_conditions["sqlSegment"]} " unless merged_conditions["sqlSegment"].blank?
        merged_conditions["paramArray"]
      end

      def type_condition(table_alias=nil)
        param_array = []
        quoted_table_alias = self.connection.quote_table_name(table_alias || table_name)
        quoted_inheritance_column = connection.quote_column_name(inheritance_column)
        param_array << self.connection.quote_value_for_pstmt(sti_name)
        type_condition = subclasses.inject("#{quoted_table_alias}.#{quoted_inheritance_column} = ? ") do |condition, subclass|
          param_array << self.connection.quote_value_for_pstmt(subclass.sti_name)
          condition << "OR #{quoted_table_alias}.#{quoted_inheritance_column} = ? "
        end

        [" (#{type_condition}) "] + param_array
      end

      def attribute_condition(quoted_column_name, argument)
        case argument
          when nil   then "#{quoted_column_name} IS NULL"
          when Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::NamedScope::Scope then "#{quoted_column_name} IN (?)"
          when Range then if argument.exclude_end?
                            "#{quoted_column_name} >= ? AND #{quoted_column_name} < ?"
                          else
                            "#{quoted_column_name} BETWEEN ? AND ?"
                          end
          else            "#{quoted_column_name} = ?"
        end
      end

      private :add_conditions!, :type_condition, :attribute_condition

      # Sanitizes a hash of attribute/value pairs into SQL conditions for a SET clause.
      #   { :status => nil, :group_id => 1 }
      #     # => "status = NULL , group_id = 1"
      def sanitize_sql_hash_for_assignment(attrs)
        return_hash = {}
        return_hash["paramArray"] = []

        return_hash["sqlSegment"] = attrs.map do |attr, value|
          return_hash["paramArray"] += quote_bound_value(value)
          "#{connection.quote_column_name(attr)} = ?"
        end.join(', ')
        return_hash
      end

      # Accepts an array, hash, or string of SQL conditions and sanitizes
      # them into a valid SQL fragment for a SET clause.
      #   { :name => nil, :group_id => 4 }  returns "name = NULL , group_id='4'"
      def sanitize_sql_for_assignment(assignments)
        return_hash = {}
        case assignments
          when Array; sanitize_sql_array(assignments)
          when Hash;  sanitize_sql_hash_for_assignment(assignments)
          else        
            return_hash["sqlSegment"] = assignments
            return_hash["paramArray"] = nil
            return_hash
        end
      end
	  
      def sanitize_sql_for_conditions(condition, table_name = quoted_table_name)
        return nil if condition.blank?

        return_hash = {}

        case condition
          when Array; sanitize_sql_array(condition)
          when Hash;  sanitize_sql_hash_for_conditions(condition, table_name)
          else
            return_hash["sqlSegment"] = condition
            return_hash["paramArray"] = nil
            return_hash
        end
      end
      alias_method :sanitize_sql, :sanitize_sql_for_conditions 
      alias_method :sanitize_conditions, :sanitize_sql_for_conditions

      # Accepts an array of conditions.  The array has each value
      # sanitized and interpolated into the SQL statement.
      def sanitize_sql_array(ary)
        statement, *values = ary
        return_hash = {}

        if values.first.is_a?(Hash) and statement =~ /:\w+/
          replace_named_bind_variables(statement, values.first)
        elsif statement && statement.include?('?')
          replace_bind_variables(statement, values)
        else
          if !values.nil? && values.size > 0
            return_hash["sqlSegment"] = statement % values.collect { |value| connection.quote_string(value.to_s) }
          else
            return_hash["sqlSegment"] = statement
          end
          return_hash["paramArray"] = []
          return_hash
        end
      end

      def sanitize_sql_hash_for_conditions(attrs, table_name = quoted_table_name)
        attrs = expand_hash_conditions_for_aggregates(attrs)
        temp_table_name = table_name

        param_array = []

        conditions = attrs.map do |attr, value|
          unless value.is_a?(Hash)
            attr = attr.to_s

            # Extract table name from qualified attribute names.
            if attr.include?('.')
              table_name, attr = attr.split('.', 2)
              table_name = connection.quote_table_name(table_name)
            else
              table_name = temp_table_name
            end

            param_array << value unless value.nil?
            attribute_condition("#{table_name}.#{connection.quote_column_name(attr)}", value)
          else
            sql_param_hash = sanitize_sql_hash_for_conditions(value, connection.quote_table_name(attr.to_s))
            param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].empty?
            sql_param_hash["sqlSegment"]
          end
        end.join(' AND ')

        replace_bind_variables(conditions, expand_range_bind_variables(param_array))
      end
      alias_method :sanitize_sql_hash, :sanitize_sql_hash_for_conditions

      # Check delete_all method, which passes a ? and array of params, as an example.
      # This method replace_bind_variables replaces those ? with a string of the values.
      # For Eg:- if said Wood.delete([1234]), delete all sends the condition as ["id in (?)", [1,2,3,4]]
      # This method sends the condition part back as string, "id in (1,2,3,4)" originally
      # Now this method is modified to send out a hash containing the parameter array and the sql to be prepared
      def replace_bind_variables(statement, values)
        raise_if_bind_arity_mismatch(statement, statement.count('?'), values.size)
        bound = values.dup
        return_hash = {}
        return_hash["paramArray"] = []
        return_hash["sqlSegment"] = ''

        return_hash["sqlSegment"] = 
           statement.gsub('?') {
              str_seg = ''
              param_array = quote_bound_value(bound.shift)
              if param_array && param_array.size > 1
                for index in 0...param_array.size-1
                  str_seg << '?,'
                end
              end
              str_seg << '?'
              return_hash["paramArray"] = return_hash["paramArray"] + param_array unless param_array.nil?
              str_seg
            }
        return_hash
      end

      # Replaces the named parameters with '?' and pass a hash containing the sql's condition clause segment and the parameters array
      def replace_named_bind_variables(statement, bind_vars) #:nodoc:
        return_hash = {}
        return_hash["paramArray"] = []
        return_hash["sqlSegment"] = ''

        return_hash["sqlSegment"] =
          statement.gsub(/(:?):([a-zA-Z]\w*)/) {

            if $1 == ':' # skip postgresql casts
              $& # return the whole match
            elsif bind_vars.include?(match = $2.to_sym)
              str_seg = ''
              param_array = quote_bound_value(bind_vars[match])
              if param_array.size > 1
                for index in 0...param_array.size-1
                  str_seg << '?,'
                end
              end
              str_seg << '?'
              return_hash["paramArray"] = return_hash["paramArray"] + param_array
              str_seg
            else
              raise PreparedStatementInvalid, "missing value for :#{match} in #{statement}"
            end
          }
        return_hash
      end

      # Returns an array of parameter values, with the values respectively quoted if of type date time or is nil
      def quote_bound_value(value) #:nodoc:
        if value.respond_to?(:map) && !value.acts_like?(:string)
          if (value.respond_to?(:empty?) && value.empty?) || value.nil?
            [nil]
          else
            value.map { |v| 
                connection.quote_value_for_pstmt(v)
            }
          end
        else
          [connection.quote_value_for_pstmt(value)]
        end
      end
      protected :replace_bind_variables, :quote_bound_value,:replace_named_bind_variables 
      protected :sanitize_sql_array, :sanitize_sql_for_conditions, :sanitize_sql_hash_for_conditions
    end #End of class << self
  end #End of class Base

  module Calculations
  #Visit back. This is still not complete. Visit back after checking method construct_scope
    module ClassMethods
      def construct_calculation_sql(operation, column_name, options) #:nodoc:
        return_hash = {}
        return_hash["paramArray"] = []
        parameter_array = []

        operation = operation.to_s.downcase
        options = options.symbolize_keys

        scope           = scope(:find)
        merged_includes = merge_includes(scope ? scope[:include] : [], options[:include])
        aggregate_alias = column_alias_for(operation, column_name)
        column_name     = "#{connection.quote_table_name(table_name)}.#{column_name}" if column_names.include?(column_name.to_s)

        if operation == 'count'
          if merged_includes.any?
            options[:distinct] = true
            column_name = options[:select] || [connection.quote_table_name(table_name), primary_key] * '.'
          end

          if options[:distinct]
            use_workaround = !connection.supports_count_distinct?
          end
        end

        if options[:distinct] && column_name.to_s !~ /\s*DISTINCT\s+/i
          distinct = 'DISTINCT ' 
        end
        sql = "SELECT #{operation}(#{distinct}#{column_name}) AS #{aggregate_alias}"

        # A (slower) workaround if we're using a backend, like sqlite, that doesn't support COUNT DISTINCT.
        sql = "SELECT COUNT(*) AS #{aggregate_alias}" if use_workaround

        sql << ", #{options[:group_field]} AS #{options[:group_alias]}" if options[:group]
        if options[:from]
          sql << " FROM #{options[:from]} "
        else
          sql << " FROM (SELECT #{distinct}#{column_name}" if use_workaround
          sql << " FROM #{connection.quote_table_name(table_name)} "
        end

        joins = ""
        param_array = add_joins!(joins, options[:joins], scope)

        if merged_includes.any?
          join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merged_includes, joins)
          sql << join_dependency.join_associations.collect{|join| 
                       sql_param_hash = join.association_join
                       parameter_array = parameter_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
                       sql_param_hash["sqlSegment"]
                    }.join
        end

        unless joins.blank?
          sql << joins
          parameter_array = parameter_array + param_array unless param_array.nil?
        end

        parameter_array = parameter_array + add_conditions!(sql, options[:conditions], scope)
        parameter_array = parameter_array + add_limited_ids_condition!(sql, options, join_dependency) if join_dependency && !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        if options[:group]
          group_key = connection.adapter_name == 'FrontBase' ?  :group_alias : :group_field
          sql << " GROUP BY #{options[group_key]} "
        end

        if options[:group] && options[:having]
          having = sanitize_sql_for_conditions(options[:having])

          sql << " HAVING #{having["sqlSegment"]} "
          parameter_array = parameter_array + having["paramArray"] unless having["paramArray"].nil?
        end

        sql << " ORDER BY #{options[:order]} "       if options[:order]

        temp_options = options.dup # Ensure that the necessary parameters are received in the duplicate, so that the original hash is intact
        temp_options[:paramArray] = [] # To receive the values for limit and offset.
        add_limit!(sql, temp_options, scope)
        parameter_array = parameter_array + temp_options[:paramArray]

        sql << ") #{aggregate_alias}_subquery" if use_workaround

        return_hash["sqlSegment"] = sql
        return_hash["paramArray"] = parameter_array
        return_hash
      end
	  
      def execute_simple_calculation(operation, column_name, column, options) #:nodoc:
        result = connection.prepared_select(construct_calculation_sql(operation, column_name, options))
        value  = result.first.values.first if result # If result set conatins a row then pick the first value of the first row
        type_cast_calculated_value(value, column, operation)
      end

      def execute_grouped_calculation(operation, column_name, column, options) #:nodoc:
        group_attr      = options[:group].to_s
        association     = reflect_on_association(group_attr.to_sym)
        associated      = association && association.macro == :belongs_to # only count belongs_to associations
        group_field     = associated ? association.primary_key_name : group_attr
        group_alias     = column_alias_for(group_field)
        group_column    = column_for group_field
        sql             = construct_calculation_sql(operation, column_name, options.merge(:group_field => group_field, :group_alias => group_alias))
        calculated_data = connection.prepared_select(sql)
        aggregate_alias = column_alias_for(operation, column_name)

        if association
          key_ids     = calculated_data.collect { |row| row[group_alias] }
          key_records = association.klass.base_class.find(key_ids)
          key_records = key_records.inject({}) { |hsh, r| hsh.merge(r.id => r) }
        end

        calculated_data.inject(ActiveSupport::OrderedHash.new) do |all, row|
          key   = type_cast_calculated_value(row[group_alias], group_column)
          key   = key_records[key] if associated
          value = row[aggregate_alias]
          all[key] = type_cast_calculated_value(value, column, operation)
          all
        end
      end

      protected :construct_calculation_sql, :execute_simple_calculation, :execute_grouped_calculation
    end # End of module classMethods
  end #End of module calculations

  class Migrator

    class << self
      def get_all_versions
        sql = "SELECT version FROM #{schema_migrations_table_name}"
        # Check method prepared_select_values signature to know the reason for the hash in the argument below
        Base.connection.prepared_select_values({"sqlSegment" => sql, "paramArray" => nil}).map(&:to_i).sort
      end
    end

    def record_version_state_after_migrating(version)
      sm_table = self.class.schema_migrations_table_name

      paramArray = []
      @migrated_versions ||= []
      if down?
        @migrated_versions.delete(version.to_i)
        pstmt = Base.connection.prepare("DELETE FROM #{sm_table} WHERE version = ? ")
        paramArray << Base.connection.quote_value_for_pstmt(version)
        Base.connection.prepared_update(pstmt, paramArray)
      else
        @migrated_versions.push(version.to_i).sort!
        pstmt = Base.connection.prepare("INSERT INTO #{sm_table} (version) VALUES (?)")
        paramArray << Base.connection.quote_value_for_pstmt(version)
        Base.connection.execute_prepared_stmt(pstmt, paramArray)
      end
    end
    private :record_version_state_after_migrating
  end

  module AssociationPreload 
    module ClassMethods

      def preload_belongs_to_association(records, reflection, preload_options={})
        return if records.first.send("loaded_#{reflection.name}?")
        options = reflection.options
        primary_key_name = reflection.primary_key_name

        if options[:polymorphic]
          polymorph_type = options[:foreign_type]
          klasses_and_ids = {}

          # Construct a mapping from klass to a list of ids to load and a mapping of those ids back to their parent_records
          records.each do |record|
            if klass = record.send(polymorph_type)
              klass_id = record.send(primary_key_name)
              if klass_id
                id_map = klasses_and_ids[klass] ||= {}
                id_list_for_klass_id = (id_map[klass_id.to_s] ||= [])
                id_list_for_klass_id << record
              end
            end
          end
          klasses_and_ids = klasses_and_ids.to_a
        else
          id_map = {}
          records.each do |record|
            key = record.send(primary_key_name)
            if key
              mapped_records = (id_map[key.to_s] ||= [])
              mapped_records << record
            end
          end
          klasses_and_ids = [[reflection.klass.name, id_map]]
        end

        klasses_and_ids.each do |klass_and_id|
          klass_name, id_map = *klass_and_id
          next if id_map.empty?
          klass = klass_name.constantize

          table_name = klass.quoted_table_name
          primary_key = klass.primary_key
          column_type = klass.columns.detect{|c| c.name == primary_key}.type
          ids = id_map.keys.map do |id|
            if column_type == :integer
              id.to_i
            elsif column_type == :float
              id.to_f
            else
              id
            end
          end
          conditions = "#{table_name}.#{connection.quote_column_name(primary_key)} #{in_or_equals_for_ids(ids)}"

          sql_segment, *parameterArray = append_conditions(reflection, preload_options)
          conditions << sql_segment
          parameterArray = [] if parameterArray.nil?

          associated_records = klass.with_exclusive_scope do
            klass.find(:all, :conditions => [conditions, ids] + parameterArray,
                                          :include => options[:include],
                                          :select => options[:select],
                                          :joins => options[:joins],
                                          :order => options[:order])
          end
          set_association_single_records(id_map, reflection.name, associated_records, primary_key)
        end
      end

      def preload_has_and_belongs_to_many_association(records, reflection, preload_options={})
        table_name = reflection.klass.quoted_table_name
        id_to_record_map, ids = construct_id_map(records)
        records.each {|record| record.send(reflection.name).loaded}
        options = reflection.options

        conditions = "t0.#{reflection.primary_key_name} #{in_or_equals_for_ids(ids)}"
        sql_segment, *paramterArray = append_conditions(reflection, preload_options)
        conditions << sql_segment
        parameterArray = [] if parameterArray.nil?

        associated_records = reflection.klass.with_exclusive_scope do
          reflection.klass.find(:all, :conditions => [conditions, ids] + parameterArray,
            :include => options[:include],
            :joins => "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{reflection.klass.quoted_table_name}.#{reflection.klass.primary_key} = t0.#{reflection.association_foreign_key}",
            :select => "#{options[:select] || table_name+'.*'}, t0.#{reflection.primary_key_name} as the_parent_record_id",
            :order => options[:order])
        end
        set_association_collection_records(id_to_record_map, reflection.name, associated_records, 'the_parent_record_id')
      end

      def find_associated_records(ids, reflection, preload_options)
        options = reflection.options
        table_name = reflection.klass.quoted_table_name

        if interface = reflection.options[:as]
          conditions = "#{reflection.klass.quoted_table_name}.#{connection.quote_column_name "#{interface}_id"} #{in_or_equals_for_ids(ids)} and #{reflection.klass.quoted_table_name}.#{connection.quote_column_name "#{interface}_type"} = '#{self.base_class.sti_name}'"
        else
          foreign_key = reflection.primary_key_name
          conditions = "#{reflection.klass.quoted_table_name}.#{foreign_key} #{in_or_equals_for_ids(ids)}"
        end

        sql_segment, *parameterArray = append_conditions(reflection, preload_options)
        conditions << sql_segment
        parameterArray = [] if parameterArray.nil?

        reflection.klass.with_exclusive_scope do
          reflection.klass.find(:all,
                              :select => (preload_options[:select] || options[:select] || "#{table_name}.*"),
                              :include => preload_options[:include] || options[:include],
                              :conditions => [conditions, ids] + parameterArray,
                              :joins => options[:joins],
                              :group => preload_options[:group] || options[:group],
                              :order => preload_options[:order] || options[:order])
        end
      end

      def append_conditions(reflection, preload_options)
        param_array = []
        sql = ""
        if sql_param_hash = reflection.sanitized_conditions
          sql << " AND (#{interpolate_sql_for_preload(sql_param_hash["sqlSegment"])})"
          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
        end
        if preload_options[:conditions]
          sql_param_hash = sanitize_sql preload_options[:conditions]
          sql << " AND (#{sql_param_hash["sqlSegment"]})"
          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
        end
        [sql] + param_array
      end

      private :append_conditions, :find_associated_records, :preload_belongs_to_association
      private :preload_has_and_belongs_to_many_association
    end # End of module ClassMethods
  end # End of  module AssociationPreload 

   module Associations

    module ClassMethods
      def joined_tables(options)
        scope = scope(:find)

        if options[:joins].is_a?(Hash) && options[:joins].has_key?("pstmt_hook")
          param_array = options[:joins]["pstmt_hook"]["paramArray"]
          joins = options[:joins]["pstmt_hook"]["sqlSegment"]
        else
          joins = options[:joins]
        end

        merged_joins = scope && scope[:joins] && joins ? merge_joins(scope[:joins], joins)["pstmt_hook"]["sqlSegment"] : (joins || scope && scope[:joins])
        [table_name] + case merged_joins
        when Symbol, Hash, Array
          if array_of_strings?(merged_joins)
            tables_in_string(merged_joins.join(' '))
          else
            join_dependency = ActiveRecord::Associations::ClassMethods::InnerJoinDependency.new(self, merged_joins, nil)
            join_dependency.join_associations.collect {|join_association| [join_association.aliased_join_table_name, join_association.aliased_table_name]}.flatten.compact
          end
        else
          tables_in_string(merged_joins)
        end
      end
      private :joined_tables
    end

    class HasOneAssociation < BelongsToAssociation
      def find_target
        @reflection.klass.find(:first, 
          :conditions => [@finder_sql] + @finder_sql_param_array,
          :select     => @reflection.options[:select],
          :order      => @reflection.options[:order], 
          :include    => @reflection.options[:include],
          :readonly   => @reflection.options[:readonly]
        )
      end

      def construct_sql
        @finder_sql_param_array = []
        case
          when @reflection.options[:as]
            @finder_sql = 
              "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = ? AND " +
              "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = ?"
            @finder_sql_param_array << owner_quoted_id
            @finder_sql_param_array << @owner.class.quote_value(@owner.class.base_class.name.to_s)
          else
            @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = ?"
            @finder_sql_param_array << owner_quoted_id
        end
          if conditions
            condition, *parameters = conditions
            @finder_sql << " AND (#{condition})"
            @finder_sql_param_array = @finder_sql_param_array + parameters unless parameters.nil?
          end
      end
    end # End of class HasOneAssociation < BelongsToAssociation

    class HasManyThroughAssociation < HasManyAssociation
      # Build SQL conditions from attributes, qualified by table name.
      def construct_conditions
        param_array = []
        table_name = @reflection.through_reflection.quoted_table_name
        conditions = construct_quoted_owner_attributes(@reflection.through_reflection).map do |attr, value|
          param_array = param_array + [value]
          "#{table_name}.#{attr} = ?"
        end

        if sql_param_hash = sql_conditions
          conditions << sql_param_hash["sqlSegment"] unless sql_param_hash["sqlSegment"].blank?
          param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
        end
        ["(" + conditions.join(') AND (') + ")"] + param_array
      end

      def construct_joins(custom_joins = nil)
        polymorphic_join = nil
        parameterArray = []

        if @reflection.source_reflection.macro == :belongs_to
          reflection_primary_key = @reflection.klass.primary_key
          source_primary_key     = @reflection.source_reflection.primary_key_name
          if @reflection.options[:source_type]
            polymorphic_join = "AND %s.%s = ?" % [
              @reflection.through_reflection.quoted_table_name, "#{@reflection.source_reflection.options[:foreign_type]}"
            ]
            parameterArray = [@owner.class.quote_value(@reflection.options[:source_type])]
          end
        else
          reflection_primary_key = @reflection.source_reflection.primary_key_name
          source_primary_key     = @reflection.through_reflection.klass.primary_key
          if @reflection.source_reflection.options[:as]
            polymorphic_join = "AND %s.%s = ?" % [
              @reflection.quoted_table_name, "#{@reflection.source_reflection.options[:as]}_type"
            ]
            parameterArray = [@owner.class.quote_value(@reflection.through_reflection.klass.name)]
          end
        end

        sql_param_hash = {"sqlSegment" => 
                            "INNER JOIN %s ON %s.%s = %s.%s %s #{@reflection.options[:joins]} #{custom_joins}" % [
                              @reflection.through_reflection.quoted_table_name,
                              @reflection.quoted_table_name, reflection_primary_key,
                              @reflection.through_reflection.quoted_table_name, source_primary_key,
                              polymorphic_join
                            ]
                         }
        sql_param_hash["paramArray"] = parameterArray
        {"pstmt_hook" => sql_param_hash}
      end

      def construct_sql
        case
          when @reflection.options[:finder_sql]
            # Not found a test case yet. Also the below 2 lines are a bit ambiguous, because finder_sql is been re assigned
            @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

            @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = ?"
            @finder_sql_param_array = [owner_quoted_id]
            if conditions
              condition, *parameters = conditions
              @finder_sql << " AND (#{condition})"
              @finder_sql_param_array = @finder_sql_param_array + parameters unless parameters.nil?
            end
          else
            @finder_sql, *@finder_sql_param_array =  construct_conditions
        end

        if @reflection.options[:counter_sql]
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        elsif @reflection.options[:finder_sql]
          # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
          @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        else
          @counter_sql = @finder_sql
          @counter_sql_param_array = @finder_sql_param_array
        end
      end

      def build_conditions
        sql_param_hash = {}
        param_array = []
        association_conditions = @reflection.options[:conditions]
        through_conditions = build_through_conditions
        source_conditions = @reflection.source_reflection.options[:conditions]
        uses_sti = !@reflection.through_reflection.klass.descends_from_active_record?

        if association_conditions || through_conditions || source_conditions || uses_sti
          all = []

          [association_conditions, source_conditions].each do |conditions|
            if conditions
              returned_hash = sanitize_sql(conditions)
              all << interpolate_sql(returned_hash["sqlSegment"])
              param_array = param_array + returned_hash["paramArray"] unless returned_hash["paramArray"].nil?
            end
          end

          if !through_conditions["sqlSegment"].blank?
            all << through_conditions["sqlSegment"]
            param_array = param_array + through_conditions["paramArray"] unless through_conditions["paramArray"].nil?
          end

          if uses_sti
            sqlsegment, *parameterArray = build_sti_condition
            all << sqlsegment
            param_array = param_array + parameterArray
          end

          sql_param_hash["sqlSegment"] = all.map { |sql| "(#{sql})" } * ' AND '
          sql_param_hash["paramArray"] = param_array
          sql_param_hash
        end
      end

      def build_through_conditions
        sql_param_hash = {}
        conditions = @reflection.through_reflection.options[:conditions]
        if conditions.is_a?(Hash)
          sql_param_hash = sanitize_sql(conditions)
          sql_param_hash["sqlSegment"] = interpolate_sql(sql_param_hash["sqlSegment"]).gsub(
            @reflection.quoted_table_name,
            @reflection.through_reflection.quoted_table_name)
        elsif conditions
          sql_param_hash = sanitize_sql(conditions)
          sql_param_hash["sqlSegment"] = interpolate_sql(sql_param_hash["sqlSegment"])
        end
        sql_param_hash
      end

      protected :construct_sql, :construct_scope, :construct_conditions, :construct_joins
      protected :build_through_conditions, :build_conditions
    end # End of class HasManyThroughAssociation < HasManyAssociation

    class HasManyAssociation < AssociationCollection
      def count_records
        count = if has_cached_counter?
          @owner.send(:read_attribute, cached_counter_attribute_name)
        elsif @reflection.options[:counter_sql]
          @reflection.klass.count_by_sql(@counter_sql)
        else
          @reflection.klass.count(:conditions => [@counter_sql] + @counter_sql_param_array , :include => @reflection.options[:include])
        end

        # If there's nothing in the database and @target has no new records
        # we are certain the current target is an empty array. This is a
        # documented side-effect of the method that may avoid an extra SELECT.
        @target ||= [] and loaded if count == 0
          
        if @reflection.options[:limit]
          count = [ @reflection.options[:limit], count ].min
        end
         
        return count
      end

      def construct_sql
        @finder_sql_param_array = []
        case
          when @reflection.options[:finder_sql]
            @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

          when @reflection.options[:as]
            @finder_sql = 
              "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = ? AND " +
              "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = ?"
            @finder_sql_param_array << owner_quoted_id
            @finder_sql_param_array << @owner.class.quote_value(@owner.class.base_class.name.to_s)
            if conditions
              condition, *parameters = conditions
              @finder_sql << " AND (#{condition})"
              @finder_sql_param_array = @finder_sql_param_array + parameters unless parameters.nil?
            end
            
          else
            @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = ?"
            @finder_sql_param_array << [owner_quoted_id]
            if conditions
              condition, *parameters = conditions
              @finder_sql << " AND (#{condition})"
              @finder_sql_param_array = @finder_sql_param_array + parameters unless parameters.nil?
            end
        end

        if @reflection.options[:counter_sql]
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        elsif @reflection.options[:finder_sql]
          # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
          @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        else
          @counter_sql = @finder_sql
          @counter_sql_param_array = @finder_sql_param_array
        end
      end

      # Deletes the records according to the <tt>:dependent</tt> option.
      def delete_records(records)
        case @reflection.options[:dependent]
          when :destroy
            records.each { |r| r.destroy }
          when :delete_all
            @reflection.klass.delete(records.map { |record| record.id })
          else
            ids = quoted_record_ids(records)
            @reflection.klass.update_all(
              ["#{@reflection.primary_key_name} = ?", nil], 
              ["#{@reflection.primary_key_name} = #{owner_quoted_id} AND #{@reflection.klass.primary_key} IN (?)",ids]
            )
            @owner.class.update_counters(@owner.id, cached_counter_attribute_name => -records.size) if has_cached_counter?
        end
      end

      def construct_scope
        create_scoping = {}
        set_belongs_to_association_for(create_scoping)
        {
          :find => { :conditions => [@finder_sql] + @finder_sql_param_array, :readonly => false, :order => @reflection.options[:order], :limit => @reflection.options[:limit], :include => @reflection.options[:include]},
          :create => create_scoping
        }
      end

      protected :construct_sql, :delete_records, :construct_scope, :count_records
    end # End of class HasManyAssociation

    class AssociationCollection < AssociationProxy
      def find(*args)
        options = args.extract_options!

        param_array = []
        # If using a custom finder_sql, scan the entire collection.
        if @reflection.options[:finder_sql]
          expects_array = args.first.kind_of?(Array)
          ids           = args.flatten.compact.uniq.map { |arg| arg.to_i }

          if ids.size == 1
            id = ids.first
            record = load_target.detect { |r| id == r.id }
            expects_array ? [ record ] : record
          else
            load_target.select { |r| ids.include?(r.id) }
          end
        else
          conditions = "#{@finder_sql}"
          param_array = param_array + @finder_sql_param_array unless @finder_sql_param_array.nil?
          if sanitized_conditions = sanitize_sql(options[:conditions])
            conditions << " AND (#{sanitized_conditions["sqlSegment"]})"
            unless sanitized_conditions["paramArray"].nil?
              param_array = param_array + sanitized_conditions["paramArray"]
            end
          end

          if param_array.nil?
            options[:conditions] = conditions
          else
            options[:conditions] = [conditions] + param_array
          end

          if options[:order] && @reflection.options[:order]
            options[:order] = "#{options[:order]}, #{@reflection.options[:order]}"
          elsif @reflection.options[:order]
            options[:order] = @reflection.options[:order]
          end
          
          # Build options specific to association
          construct_find_options!(options)
          
          merge_options_from_reflection!(options)

          # Pass through args exactly as we received them.
          args << options
          @reflection.klass.find(*args)
        end
      end
    end # End of class AssociationCollection

    module ClassMethods
      def select_all_rows(options, join_dependency)
        connection.prepared_select(
          construct_finder_sql_with_included_associations(options, join_dependency),
          "#{name} Load Including Associations"
        )
      end

      def construct_finder_sql_with_included_associations(options, join_dependency)
        param_array = []
        scope = scope(:find)
        sql = "SELECT #{column_aliases(join_dependency)} FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "
        sql << join_dependency.join_associations.collect{|join| 
                  sql_param_hash = join.association_join 
                  param_array = param_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
                  sql_param_hash["sqlSegment"]
               }.join

        param_array = param_array + add_joins!(sql, options[:joins], scope)
        param_array = param_array + add_conditions!(sql, options[:conditions], scope)
        param_array = param_array + add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        param_array = param_array + add_group!(sql, options[:group], options[:having], scope)
        add_order!(sql, options[:order], scope)

        temp_options = options.dup # Ensure that the necessary parameters are received in the duplicate, so that the original hash is intact
        temp_options[:paramArray] = [] # To receive the values for limit and offset.
        add_limit!(sql, temp_options, scope) if using_limitable_reflections?(join_dependency.reflections)
        param_array = param_array + temp_options[:paramArray]

        add_lock!(sql, options, scope)

        return sanitize_sql([sql] + param_array)
      end

      def add_limited_ids_condition!(sql, options, join_dependency)
        unless (id_list = select_limited_ids_list(options, join_dependency)).empty?
          sql_segment = id_list.map{ '?'}.join(', ')
          sql << "#{condition_word(sql)} #{connection.quote_table_name table_name}.#{primary_key} IN (#{sql_segment}) "
          id_list
        else
          throw :invalid_query
        end
      end

      def select_limited_ids_list(options, join_dependency)
        pk = columns_hash[primary_key]
        connection.prepared_select(
          construct_finder_sql_for_association_limiting(options, join_dependency),
          "#{name} Load IDs For Limited Eager Loading"
        ).collect { |row| connection.quote_value_for_pstmt(row[primary_key], pk) }
      end

      def construct_finder_sql_for_association_limiting(options, join_dependency)
        scope       = scope(:find)

        parameter_array = []

        # Only join tables referenced in order or conditions since this is particularly slow on the pre-query.
        tables_from_conditions = conditions_tables(options)
        tables_from_order      = order_tables(options)
        all_tables             = tables_from_conditions + tables_from_order
        distinct_join_associations = all_tables.uniq.map{|table|
          join_dependency.joins_for_table_name(table)
        }.flatten.compact.uniq

        order = options[:order]
        if scoped_order = (scope && scope[:order])
          order = order ? "#{order}, #{scoped_order}" : scoped_order
        end

        is_distinct = !options[:joins].blank? || include_eager_conditions?(options, tables_from_conditions) || include_eager_order?(options, tables_from_order)
        sql = "SELECT "
        if is_distinct
          sql << connection.distinct("#{connection.quote_table_name table_name}.#{primary_key}", order)
        else
          sql << primary_key
        end
        sql << " FROM #{connection.quote_table_name table_name} "

        if is_distinct
          sql << distinct_join_associations.collect { |assoc| 
                      sql_param_hash = assoc.association_join
                      parameter_array = parameter_array + sql_param_hash["paramArray"]
                      sql_param_hash["sqlSegment"]
                    }.join
          parameter_array = parameter_array + add_joins!(sql, options[:joins], scope)
        end

        parameter_array = parameter_array + add_conditions!(sql, options[:conditions], scope)
        parameter_array = parameter_array + add_group!(sql, options[:group], options[:having], scope)

        if order && is_distinct
          connection.add_order_by_for_association_limiting!(sql, :order => order)
        else
          add_order!(sql, options[:order], scope)
        end

        temp_options = options.dup # Ensure that the necessary parameters are received in the duplicate, so that the original hash is intact
        temp_options[:paramArray] = [] # To receive the values for limit and offset.
        add_limit!(sql, temp_options, scope)
        parameter_array = parameter_array + temp_options[:paramArray]

        return sanitize_sql([sql] + parameter_array)
      end

      def configure_dependency_for_has_many(reflection, extra_conditions = nil)
        if reflection.options.include?(:dependent)
          # Add polymorphic type if the :as option is present
          dependent_conditions = []
          param_array = []
          #record.quoted_id is to be passed. But the evaluation is deffered, hence this is to be passed in module_eval in case delete_all below
          dependent_conditions << "#{reflection.primary_key_name} = ?" # The value is passed in below in respective cases
          if reflection.options[:as]
            dependent_conditions << "#{reflection.options[:as]}_type = ?"
            param_array << base_class.name
          end
          if reflection.options[:conditions]
            sql_param_hash = sanitize_sql(reflection.options[:conditions], reflection.quoted_table_name)
            dependent_conditions << sql_param_hash["sqlSegment"]
            param_array = param_array + sql_param_hash["paramArray"] if !sql_param_hash["paramArray"].nil?
          end
          dependent_conditions << extra_conditions if extra_conditions
          dependent_conditions = dependent_conditions.collect {|where| "(#{where})" }.join(" AND ")
          dependent_conditions = dependent_conditions.gsub('@', '\@')
          case reflection.options[:dependent]
            when :destroy
              method_name = "has_many_dependent_destroy_for_#{reflection.name}".to_sym
              define_method(method_name) do
                send(reflection.name).each { |o| o.destroy }
              end
              before_destroy method_name
            when :delete_all
              module_eval %Q{
                before_destroy do |record|
                  delete_all_has_many_dependencies(record,
                    "#{reflection.name}",
                    #{reflection.class_name},
                    [dependent_conditions] + ["\#{record.#{reflection.name}.send(:owner_quoted_id)}"] + param_array)
                end
              }
            when :nullify
              module_eval %Q{
                before_destroy do |record|
                  nullify_has_many_dependencies(record,
                    "#{reflection.name}",
                    #{reflection.class_name},
                    "#{reflection.primary_key_name}",
                    [dependent_conditions] + ["\#{record.#{reflection.name}.send(:owner_quoted_id)}"] + param_array)
                end
              }
            else
              raise ArgumentError, "The :dependent option expects either :destroy, :delete_all, or :nullify (#{reflection.options[:dependent].inspect})"
          end
        end
      end
      private :select_all_rows, :construct_finder_sql_with_included_associations
      private :configure_dependency_for_has_many
      private :construct_finder_sql_for_association_limiting, :select_limited_ids_list, :add_limited_ids_condition!

      class JoinDependency
        class JoinAssociation < JoinBase
          def association_join
            return_hash = {} # A Hash to conatin the parameterised sql and the parameters
            parameter_array = []

            connection = reflection.active_record.connection
            join = case reflection.macro
              when :has_and_belongs_to_many
                " #{join_type} %s ON %s.%s = %s.%s " % [
                   table_alias_for(options[:join_table], aliased_join_table_name),
                   connection.quote_table_name(aliased_join_table_name),
                   options[:foreign_key] || reflection.active_record.to_s.foreign_key,
                   connection.quote_table_name(parent.aliased_table_name),
                   reflection.active_record.primary_key] +
                " #{join_type} %s ON %s.%s = %s.%s " % [
                   table_name_and_alias,
                   connection.quote_table_name(aliased_table_name),
                   klass.primary_key,
                   connection.quote_table_name(aliased_join_table_name),
                   options[:association_foreign_key] || klass.to_s.foreign_key
                   ]
              when :has_many, :has_one
                case
                  when reflection.options[:through]
                    through_conditions = through_reflection.options[:conditions] ? "AND #{interpolate_sql(sanitize_sql(through_reflection.options[:conditions]))}" : ''

                    jt_foreign_key = jt_as_extra = jt_source_extra = jt_sti_extra = nil
                    first_key = second_key = as_extra = nil

                    if through_reflection.options[:as] # has_many :through against a polymorphic join
                      jt_foreign_key = through_reflection.options[:as].to_s + '_id'
                      jt_as_extra = " AND %s.%s = ?" % [
                        connection.quote_table_name(aliased_join_table_name),
                        connection.quote_column_name(through_reflection.options[:as].to_s + '_type')
                      ]
                      parameter_array = parameter_array + [klass.quote_value(parent.active_record.base_class.name)]
                    else
                      jt_foreign_key = through_reflection.primary_key_name
                    end

                    case source_reflection.macro
                    when :has_many
                      if source_reflection.options[:as]
                        first_key   = "#{source_reflection.options[:as]}_id"
                        second_key  = options[:foreign_key] || primary_key
                        parameter_array = parameter_array + [klass.quote_value(source_reflection.active_record.base_class.name)]
                        as_extra    = " AND %s.%s = ?" % [
                          connection.quote_table_name(aliased_table_name),
                          connection.quote_column_name("#{source_reflection.options[:as]}_type")
                        ]
                      else
                        first_key   = through_reflection.klass.base_class.to_s.foreign_key
                        second_key  = options[:foreign_key] || primary_key
                      end

                      unless through_reflection.klass.descends_from_active_record?
                        parameter_array = parameter_array + [through_reflection.klass.quote_value(through_reflection.klass.sti_name)]
                        jt_sti_extra = " AND %s.%s = ?" % [
                          connection.quote_table_name(aliased_join_table_name),
                          connection.quote_column_name(through_reflection.active_record.inheritance_column)
                        ]
                      end
                    when :belongs_to
                      first_key = primary_key
                      if reflection.options[:source_type]
                        second_key = source_reflection.association_foreign_key
                        parameter_array = parameter_array + [klass.quote_value(reflection.options[:source_type])]
                        jt_source_extra = " AND %s.%s = ?" % [
                          connection.quote_table_name(aliased_join_table_name),
                          connection.quote_column_name(reflection.source_reflection.options[:foreign_type])
                        ]
                      else
                        second_key = source_reflection.primary_key_name
                      end
                    end

                    " #{join_type} %s ON (%s.%s = %s.%s%s%s%s) " % [
                      table_alias_for(through_reflection.klass.table_name, aliased_join_table_name),
                      connection.quote_table_name(parent.aliased_table_name),
                      connection.quote_column_name(parent.primary_key),
                      connection.quote_table_name(aliased_join_table_name),
                      connection.quote_column_name(jt_foreign_key),
                      jt_as_extra, jt_source_extra, jt_sti_extra
                    ] +
                    " #{join_type} %s ON (%s.%s = %s.%s%s) " % [
                      table_name_and_alias,
                      connection.quote_table_name(aliased_table_name),
                      connection.quote_column_name(first_key),
                      connection.quote_table_name(aliased_join_table_name),
                      connection.quote_column_name(second_key),
                      as_extra
                    ]

                  when reflection.options[:as] && [:has_many, :has_one].include?(reflection.macro)
                    parameter_array = parameter_array + [klass.quote_value(parent.active_record.base_class.name)]
                    " #{join_type} %s ON %s.%s = %s.%s AND %s.%s = ?" % [
                      table_name_and_alias,
                      connection.quote_table_name(aliased_table_name),
                      "#{reflection.options[:as]}_id",
                      connection.quote_table_name(parent.aliased_table_name),
                      parent.primary_key,
                      connection.quote_table_name(aliased_table_name),
                      "#{reflection.options[:as]}_type"
                    ]
                  else
                    foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
                    " #{join_type} %s ON %s.%s = %s.%s " % [
                      table_name_and_alias,
                      aliased_table_name,
                      foreign_key,
                      parent.aliased_table_name,
                      reflection.options[:primary_key] || parent.primary_key
                    ]
                end
              when :belongs_to
                " #{join_type} %s ON %s.%s = %s.%s " % [
                   table_name_and_alias,
                   connection.quote_table_name(aliased_table_name),
                   reflection.klass.primary_key,
                   connection.quote_table_name(parent.aliased_table_name),
                   options[:foreign_key] || reflection.primary_key_name
                  ]
              else
                ""
            end || ''

            unless klass.descends_from_active_record?
              sql_segment, *param_array = klass.send(:type_condition, aliased_table_name)
              join << %(AND %s) % [sql_segment]
              parameter_array = parameter_array + param_array unless param_array.nil?
            end

            [through_reflection, reflection].each do |ref|
              if ref && ref.options[:conditions]
                sql_param_hash = sanitize_sql(ref.options[:conditions], aliased_table_name)
                parameter_array = parameter_array + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
                join << "AND #{interpolate_sql(sql_param_hash["sqlSegment"])} "
              end
            end

            return_hash["sqlSegment"] = join
            return_hash["paramArray"] = parameter_array
            return_hash
          end

		end # End of class JoinAssociation
      end # End of class JoinDependency
    end # End of module ClassMethods

    class AssociationProxy
      def quoted_record_ids(records)
        records.map { |record| record.quoted_id }
      end

      def conditions
        if @reflection.sanitized_conditions
          sql_param_hash = @reflection.sanitized_conditions
          temp_condition = [interpolate_sql(sql_param_hash["sqlSegment"])]
          temp_condition = temp_condition + sql_param_hash["paramArray"] unless sql_param_hash["paramArray"].nil?
          @conditions ||= temp_condition
        end
      end
      alias :sql_conditions :conditions
	  
      protected :quoted_record_ids
    end

    class HasAndBelongsToManyAssociation < AssociationCollection

      def insert_record(record, force = true, validate = true)
        if record.new_record?
          if force
            record.save!
          else
            return false unless record.save(validate)
          end
        end

        if @reflection.options[:insert_sql]
          @owner.connection.insert(interpolate_sql(@reflection.options[:insert_sql], record))
        else
          attributes = columns.inject({}) do |attrs, column|
            case column.name.to_s
              when @reflection.primary_key_name.to_s
                attrs[column.name] = owner_quoted_id
              when @reflection.association_foreign_key.to_s
                attrs[column.name] = record.quoted_id
              else
                if record.has_attribute?(column.name)
                  value = @owner.send(:quote_value, record[column.name], column)
                  attrs[column.name] = value unless value.nil?
                end
            end
            attrs
          end

          param_marker_sql_segment = attributes.values.collect{|value| '?'}.join(', ')
          sql =
            "INSERT INTO #{@owner.connection.quote_table_name @reflection.options[:join_table]} (#{@owner.send(:quoted_column_names, attributes).join(', ')}) " +
            "VALUES (#{param_marker_sql_segment})"

          pstmt = @owner.connection.prepare(sql)
          @owner.connection.prepared_insert(pstmt, attributes.values )
        end

        return true
      end

      def delete_records(records)
        paramArray = []
        if sql = @reflection.options[:delete_sql]
          records.each { |record| @owner.connection.delete(interpolate_sql(sql, record)) }
        else
          ids = quoted_record_ids(records)

          paramArray = [owner_quoted_id] + ids
          param_marker_sql_segment = ids.collect{|id| '?'}.join(', ')

          sql = "DELETE FROM #{@owner.connection.quote_table_name @reflection.options[:join_table]} WHERE #{@reflection.primary_key_name} = ? AND #{@reflection.association_foreign_key} IN (#{param_marker_sql_segment})"
          pstmt = @owner.connection.prepare(sql)
          @owner.connection.prepared_delete(pstmt,paramArray)
        end
      end

      def construct_sql
        @finder_sql_param_array = []
        if @reflection.options[:finder_sql]
          @finder_sql = interpolate_sql(@reflection.options[:finder_sql])
        else
          @finder_sql = "#{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.primary_key_name} = ? "
          @finder_sql_param_array << owner_quoted_id
          if conditions
            condition, *parameters = conditions
            @finder_sql << " AND (#{condition})"
            @finder_sql_param_array = @finder_sql_param_array + parameters unless parameters.nil?
          end
        end

        @join_sql = "INNER JOIN #{@owner.connection.quote_table_name @reflection.options[:join_table]} ON #{@reflection.quoted_table_name}.#{@reflection.klass.primary_key} = #{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.association_foreign_key}"

        if @reflection.options[:counter_sql]
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        elsif @reflection.options[:finder_sql]
          # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
          @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        else
          @counter_sql = @finder_sql
        end
      end

      def construct_scope
        { :find => {  :conditions => [@finder_sql] + @finder_sql_param_array,
                      :joins => @join_sql,
                      :readonly => false,
                      :order => @reflection.options[:order],
                      :include => @reflection.options[:include],
                      :limit => @reflection.options[:limit] } }
      end

      protected :insert_record, :delete_records, :construct_sql, :construct_scope
    end #end of class HasAndBelongsToManyAssociation

  end #end of module Associations

  module ConnectionAdapters

    module QueryCache
      class << self
        def included(base)
          base.class_eval do
            alias_method_chain :prepared_select, :query_cache
          end
        end
      end

      def prepared_select_with_query_cache(sql_param_hash, name = nil)
        if @query_cache_enabled
          cache_sql("#{sql_param_hash["sqlSegment"]} #{sql_param_hash["paramArray"]}") { prepared_select_without_query_cache(sql_param_hash, name) }
        else
          prepared_select_without_query_cache(sql_param_hash, name)
        end
      end
    end

    class IBM_DBAdapter < AbstractAdapter
      include QueryCache
    end

    module SchemaStatements
      def assume_migrated_upto_version(version)
        version = version.to_i
        sm_table = quote_table_name(ActiveRecord::Migrator.schema_migrations_table_name)

        migrated = select_values("SELECT version FROM #{sm_table}").map(&:to_i)
        versions = Dir['db/migrate/[0-9]*_*.rb'].map do |filename|
          filename.split('/').last.split('_').first.to_i
        end

        unless migrated.include?(version)
          pstmt = prepare("INSERT INTO #{sm_table} (version) VALUES (?)")
          execute_prepared_stmt(pstmt, [version])
        end

        inserted = Set.new
        (versions - migrated).each do |v|
          if inserted.include?(v)
            raise "Duplicate migration #{v}. Please renumber your migrations to resolve the conflict."
          elsif v < version
            pstmt = prepare("INSERT INTO #{sm_table} (version) VALUES (?)")
            execute_prepared_stmt(pstmt, [v])
            inserted << v
          end
        end
      end
    end # End of module SchemaStatements
  end # End of ConnectionAdapters
end #End of module Activerecord
 
class Fixtures < (RUBY_VERSION < '1.9' ? YAML::Omap : Hash)
  def delete_existing_fixtures
    pstmt = @connection.prepare "DELETE FROM #{@connection.quote_table_name(table_name)}", 'Fixture Delete'
    @connection.prepared_delete(pstmt, nil)
  end
end
