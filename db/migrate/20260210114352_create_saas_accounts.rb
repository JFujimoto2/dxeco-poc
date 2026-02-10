class CreateSaasAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :saas_accounts do |t|
      t.references :saas, null: false, foreign_key: { to_table: :saases }
      t.references :user, null: false, foreign_key: true
      t.string :account_email
      t.string :role
      t.string :status, default: "active", null: false
      t.datetime :last_login_at
      t.text :notes
      t.timestamps
    end

    add_index :saas_accounts, [ :saas_id, :user_id ], unique: true
    add_index :saas_accounts, :status
  end
end
