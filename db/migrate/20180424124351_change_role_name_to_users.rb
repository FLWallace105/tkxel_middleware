class ChangeRoleNameToUsers < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :role, :is_admin
  end
end
