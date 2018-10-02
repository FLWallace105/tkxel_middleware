class AddStatusToInventoryOnHands < ActiveRecord::Migration[5.1]
  def change
    add_column :inventory_on_hands, :status, :string
  end
end
