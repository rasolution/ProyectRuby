class CreateProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :price
      t.integer :state

      t.timestamps null: false
    end
  end
end
