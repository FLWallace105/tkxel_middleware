class CreateInventoryLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :inventory_logs do |t|
      t.string :sku
      t.string :name
      t.references :brand, foreign_key: true
      t.bigint :shopify_variant
      t.bigint :product_id

      t.timestamps
    end
  end
end
