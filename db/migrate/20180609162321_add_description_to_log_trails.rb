class AddDescriptionToLogTrails < ActiveRecord::Migration[5.1]
  def change
    add_column :log_trails, :description, :string, default: ''
  end
end
