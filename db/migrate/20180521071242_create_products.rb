class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.date :product_date
      t.boolean :is_default, default: false
      t.string :product_id
      t.references :brand, foreign_key: true
    end
  end
end
