class CreateUserBrands < ActiveRecord::Migration[5.1]
  def change
    create_table :user_brands do |t|
      t.references :brand, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
