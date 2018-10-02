class CreateJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :jobs do |t|
      t.string :name
      t.datetime :runned_at
      t.references :brand, foreign_key: true

      t.timestamps
    end
  end
end
