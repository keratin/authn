class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :username, null: false
      t.string :password, null: false
      t.datetime :password_changed_at
      t.timestamps
    end

    add_index :accounts, :username, unique: true
  end
end
