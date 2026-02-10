class CreateTaskItems < ActiveRecord::Migration[8.1]
  def change
    create_table :task_items do |t|
      t.references :task, null: false, foreign_key: true
      t.string :action_type, null: false
      t.string :description, null: false
      t.references :saas, foreign_key: { to_table: :saases }
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.datetime :completed_at
      t.text :notes

      t.timestamps
    end

    add_index :task_items, :status
  end
end
