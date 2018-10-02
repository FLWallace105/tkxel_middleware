class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.string :name
      t.text :order_detail
      t.string :source
      t.references :brand, foreign_key: true
      t.string :tracking_id
      t.integer :status
      t.decimal :price
      t.string :customer_name
      t.jsonb :details, default: '{}'

      t.timestamps
    end
    add_index  :orders, :details, using: :gin
  end
end
