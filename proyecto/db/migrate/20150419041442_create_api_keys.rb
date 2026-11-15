class CreateApiKeys < ActiveRecord::Migration[4.2]
  def change
    create_table :api_keys do |t|
      t.string :access_token
      t.string :username
      t.datetime :current

      t.timestamps null: false
    end
  end
end
