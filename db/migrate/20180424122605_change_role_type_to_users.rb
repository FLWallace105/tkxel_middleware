class ChangeRoleTypeToUsers < ActiveRecord::Migration[5.1]
  def up
    change_column :users, :role, "boolean USING role::boolean" , default: false
  end
  def down
    change_column :users, :role, :string
  end
end
