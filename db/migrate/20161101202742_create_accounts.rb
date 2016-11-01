class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :password, null: false
      t.datetime :confirmed_at
      t.timestamps
    end

    add_index :accounts, :name, unique: true
  end
end
