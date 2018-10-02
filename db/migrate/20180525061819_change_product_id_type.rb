class ChangeProductIdType < ActiveRecord::Migration[5.1]
  def change
    remove_column :products, :product_id, :string
    add_column :products, :product_id, :integer, limit: 8
  end
end
