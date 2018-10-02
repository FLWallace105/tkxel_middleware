class CreateInventoryTrails < ActiveRecord::Migration[5.1]
  def change
    create_table :inventory_trails do |t|
      t.references :inventory, foreign_key: true
      t.integer :cims_quantity
      t.integer :shopify_quantity
      t.integer :flow
      t.integer :adjustment

      t.timestamps
    end
  end
end
