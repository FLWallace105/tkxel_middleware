class AddNewFieldsForInventory < ActiveRecord::Migration[5.1]
  def change
    remove_column :inventories, :details
    remove_column :inventories, :style_id
    remove_column :inventories, :product_id
    add_column :inventories, :variant_sku, :string
    add_column :inventories, :product_type, :string
    add_column :inventories, :size, :string
    add_column :inventories, :size_count, :int
    add_column :inventories, :collection_name, :string
    add_column :inventories, :inventory_item_id, :int ,:limit => 5
    add_column :inventories, :collection_id, :int ,:limit => 5
  end
end
