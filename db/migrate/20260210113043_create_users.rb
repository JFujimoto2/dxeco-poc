class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :entra_id_sub, null: false
      t.string :email, null: false
      t.string :display_name
      t.string :department
      t.string :job_title
      t.string :employee_id
      t.boolean :account_enabled, default: true
      t.string :role, default: "viewer", null: false
      t.datetime :last_signed_in_at

      t.timestamps
    end

    add_index :users, :entra_id_sub, unique: true
    add_index :users, :email
  end
end
