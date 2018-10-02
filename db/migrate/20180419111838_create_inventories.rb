class CreateInventories < ActiveRecord::Migration[5.1]
  def change
    create_table :inventories do |t|
      t.string :product_id
      t.references :brand, foreign_key: true
      t.integer :style_id
      t.jsonb :details, default: '{}'

      t.timestamps
    end
    add_index  :inventories, :details, using: :gin
  end
end
