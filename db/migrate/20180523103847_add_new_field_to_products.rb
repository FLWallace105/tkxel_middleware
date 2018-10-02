class AddNewFieldToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :product_title, :string
  end
end
