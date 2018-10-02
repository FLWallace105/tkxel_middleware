class AddNewFieldToInventories < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :product_id,  :integer, limit: 8

  end
end
