class AddNewColoumnForReserveInventories < ActiveRecord::Migration[5.1]
  def change
    add_column :reserve_inventories, :delivered_count,  :integer
  end
end
