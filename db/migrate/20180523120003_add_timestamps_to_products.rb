class AddTimestampsToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :created_at, :datetime, null: true
    add_column :products, :updated_at, :datetime, null: true

    Product.update_all(created_at: Time.now,updated_at: Time.now)

    change_column_null :products, :created_at, false
    change_column_null :products, :updated_at, false
  end
end
