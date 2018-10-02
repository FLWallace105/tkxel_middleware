class ChangeInventoryToReserveInventory < ActiveRecord::Migration[5.1]
  def change
    rename_table :inventories, :reserve_inventories
  end
end
