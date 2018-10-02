class CreateFulfillments < ActiveRecord::Migration[5.1]
  def change
    create_table :fulfillments do |t|
      t.bigint :pick_ticket
      t.string :status
      t.references :brand, foreign_key: true

      t.timestamps
    end
  end
end
