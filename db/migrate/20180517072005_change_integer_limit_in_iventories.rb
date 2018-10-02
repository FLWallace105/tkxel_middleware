class ChangeIntegerLimitInIventories < ActiveRecord::Migration[5.1]
  def change
    change_column :inventories, :inventory_item_id, :integer, limit: 8
    change_column :inventories, :collection_id, :integer, limit: 8
  end
end
