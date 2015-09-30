require "cases/helper"
require "models/author"
require "models/binary"
require "models/cake_designer"
require "models/category"
require "models/chef"
require "models/comment"
require "models/edge"
require "models/essay"
require "models/post"
require "models/price_estimate"
require "models/topic"
require "models/treasure"
require "models/vertex"

module ActiveRecord
  class WhereTest < ActiveRecord::TestCase
    fixtures :posts, :edges, :authors, :binaries, :essays, :author_addresses
	
  unless current_adapter?(:IBM_DBAdapter)
	def test_where_with_boolean_for_string_column
      #count = Post.where(:title => false).count
	  count = Post.where(:title => 0.0).count
      assert_equal 0, count
    end
   end
	
=begin	
	def test_where_with_integer_for_binary_column
      count = Binary.where(:data => 0).count
      assert_equal 0, count
    end
=end
	    
  end
end
