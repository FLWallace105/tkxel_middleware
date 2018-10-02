class CreateLogTrails < ActiveRecord::Migration[5.1]
  def change
    create_table :log_trails do |t|
      t.references :logtrailable, polymorphic: true
      t.integer :action_type
      t.integer :recurring_tries
      t.integer :status
      t.text :headline
      t.references :brand, foreign_key: true
      t.integer :trigger_type
      t.text :log_file

      t.timestamps
    end
  end
end
