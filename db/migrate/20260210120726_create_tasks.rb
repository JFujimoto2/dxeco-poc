class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :task_type, null: false
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "open"
      t.date :due_date

      t.timestamps
    end

    add_index :tasks, :status
  end
end
