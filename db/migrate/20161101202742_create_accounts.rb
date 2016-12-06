class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :username, null: true
      t.string :password, null: true
      t.boolean :locked, null: false, default: false
      t.datetime :password_changed_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :accounts, :username, unique: true
  end
end
