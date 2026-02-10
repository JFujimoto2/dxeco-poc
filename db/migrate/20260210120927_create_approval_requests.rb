class CreateApprovalRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :approval_requests do |t|
      t.string :request_type, null: false, default: "add_account"
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :saas, foreign_key: { to_table: :saases }
      t.string :saas_name
      t.text :reason
      t.integer :estimated_cost
      t.integer :user_count
      t.string :status, null: false, default: "pending"
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.text :rejection_reason

      t.timestamps
    end

    add_index :approval_requests, :status
  end
end
