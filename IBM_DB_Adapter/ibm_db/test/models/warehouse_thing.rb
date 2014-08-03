class WarehouseThing < ActiveRecord::Base
  set_table_name "warehouse_things"

  validates_uniqueness_of :value
end