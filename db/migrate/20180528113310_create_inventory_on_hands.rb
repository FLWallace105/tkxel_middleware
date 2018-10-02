class CreateInventoryOnHands < ActiveRecord::Migration[5.1]
  def change
    create_table :inventory_on_hands do |t|
      t.string :sku
      t.references :brand, foreign_key: true
      t.float :threshold_percentage

      t.timestamps
    end
  end
end
