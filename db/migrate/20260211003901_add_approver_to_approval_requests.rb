class AddApproverToApprovalRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :approval_requests, :approver, foreign_key: { to_table: :users }, null: true
  end
end
