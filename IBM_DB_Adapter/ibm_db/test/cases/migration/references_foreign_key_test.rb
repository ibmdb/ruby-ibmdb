require 'cases/helper'

if ActiveRecord::Base.connection.supports_foreign_keys?
module ActiveRecord
  class Migration
    class ReferencesForeignKeyTest < ActiveRecord::TestCase

	
      setup do
        @connection = ActiveRecord::Base.connection
        
      end

	  
      teardown do
        @connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
      end

	  
      test "foreign keys can be created with the table" do
		@connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
	    @connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings do |t|
          t.references :testing_parent, foreign_key: true
        end

        fk = @connection.foreign_keys("testings").first
		if current_adapter?(:IBM_DBAdapter)
			assert_equal "testings".upcase, fk.from_table.upcase
			assert_equal "testing_parents".upcase, fk.to_table.upcase
		else
			assert_equal "testings", fk.from_table
			assert_equal "testing_parents", fk.to_table
		end
        
      end

      
      test "no foreign key is created by default" do
		@connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
		@connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings do |t|
          t.references :testing_parent
        end

        assert_equal [], @connection.foreign_keys("testings")
      end
	  
	        
      test "options hash can be passed" do	    
		@connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
		@connection.create_table :testing_parents, primary_key: 'other_id'              
		@connection.create_table :testings do |t|
          t.references :testing_parent, foreign_key: { primary_key: :other_id }
        end
        
		if current_adapter?(:IBM_DBAdapter)
			fk = @connection.foreign_keys("TESTINGS").find { |k| k.to_table == "TESTING_PARENTS" }		
			assert_equal "OTHER_ID", fk.primary_key
		else	
			fk = @connection.foreign_keys("testings").find { |k| k.to_table == "testing_parents" }		
			assert_equal "other_id", fk.primary_key
		end
      end	  

      
      test "foreign keys cannot be added to polymorphic relations when creating the table" do	    
		@connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
		@connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings do |t|
          assert_raises(ArgumentError) do
            t.references :testing_parent, polymorphic: true, foreign_key: true
          end
        end
      end

      
      test "foreign keys can be created while changing the table" do
        @connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"	  
		@connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings
        @connection.change_table :testings do |t|
          t.references :testing_parent, foreign_key: true
        end

        fk = @connection.foreign_keys("testings").first		
		
		if current_adapter?(:IBM_DBAdapter)
			assert_equal "testings".upcase, fk.from_table.upcase
			assert_equal "testing_parents".upcase, fk.to_table.upcase
		else
			assert_equal "testings", fk.from_table
			assert_equal "testing_parents", fk.to_table
		end
        
      end

      
      test "foreign keys are not added by default when changing the table" do 
        @connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"	  
		@connection.create_table(:testing_parents, force: true)
		@connection.create_table :testings
        @connection.change_table :testings do |t|
          t.references :testing_parent
        end

        assert_equal [], @connection.foreign_keys("testings")
      end
	  
	 
      test "foreign keys accept options when changing the table" do		
	    @connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"		
		@connection.create_table :testing_parents, primary_key: 'other_id'         
        
		@connection.create_table :testings        
		@connection.change_table :testings do |t|
          t.references :testing_parent, foreign_key: { primary_key: :other_id }
        end
		
		if current_adapter?(:IBM_DBAdapter)
			fk = @connection.foreign_keys("TESTINGS").find { |k| k.to_table == "TESTING_PARENTS" }			
			assert_equal "OTHER_ID", fk.primary_key
		else
			fk = @connection.foreign_keys("testings").find { |k| k.to_table == "testing_parents" }		
			assert_equal "other_id", fk.primary_key		
        end		
      end

	  
      test "foreign keys cannot be added to polymorphic relations when changing the table" do	 
		@connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
		@connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings
        @connection.change_table :testings do |t|
          assert_raises(ArgumentError) do
            t.references :testing_parent, polymorphic: true, foreign_key: true
          end
        end
      end

      test "foreign key column can be removed" do	    
	    @connection.drop_table("testings") if @connection.table_exists? "testings"
        @connection.drop_table("testing_parents") if @connection.table_exists? "testing_parents"
		@connection.create_table(:testing_parents, force: true)
        @connection.create_table :testings do |t|
          t.references :testing_parent, index: true, foreign_key: true
        end

        assert_difference "@connection.foreign_keys('testings').size", -1 do
          @connection.remove_reference :testings, :testing_parent, foreign_key: true
        end
      end

      test "foreign key methods respect pluralize_table_names" do
        begin
          original_pluralize_table_names = ActiveRecord::Base.pluralize_table_names
          ActiveRecord::Base.pluralize_table_names = false
		  @connection.drop_table("testing") if @connection.table_exists? "testing"
          @connection.create_table :testing
          @connection.change_table :testing_parents do |t|
            t.references :testing, foreign_key: true
          end

          fk = @connection.foreign_keys("testing_parents").first
		  if current_adapter?(:IBM_DBAdapter)
			assert_equal "testing_parents".upcase, fk.from_table.upcase
			assert_equal "testing".upcase, fk.to_table.upcase
		  else
			assert_equal "testing_parents", fk.from_table
			assert_equal "testing", fk.to_table
		  end
          

          assert_difference "@connection.foreign_keys('testing_parents').size", -1 do
            @connection.remove_reference :testing_parents, :testing, foreign_key: true
          end
        ensure
          ActiveRecord::Base.pluralize_table_names = original_pluralize_table_names
          @connection.drop_table "testing", if_exists: true
        end
      end
    end
  end
end
else
class ReferencesWithoutForeignKeySupportTest < ActiveRecord::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
    @connection.create_table(:testing_parents, force: true)
  end

  teardown do
    @connection.drop_table("testings", if_exists: true)
    @connection.drop_table("testing_parents", if_exists: true)
  end

  test "ignores foreign keys defined with the table" do
    @connection.create_table :testings do |t|
      t.references :testing_parent, foreign_key: true
    end

    assert_includes @connection.tables, "testings"
  end
end
end
