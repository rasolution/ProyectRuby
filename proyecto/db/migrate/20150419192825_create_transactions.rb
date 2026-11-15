class CreateTransactions < ActiveRecord::Migration[4.2]
  def change
    create_table :transactions do |t|
      t.integer :offert_product_id
      t.string :require_product_id

      t.timestamps null: false
    end
  end
end
