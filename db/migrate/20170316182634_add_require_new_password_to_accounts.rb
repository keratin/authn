class AddRequireNewPasswordToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :require_new_password, :boolean, default: false, null: false, after: :locked
  end
end
