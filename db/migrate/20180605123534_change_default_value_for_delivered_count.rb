class ChangeDefaultValueForDeliveredCount < ActiveRecord::Migration[5.1]
  def change
    change_column :reserve_inventories, :delivered_count,  :integer, default: 0
  end
end
