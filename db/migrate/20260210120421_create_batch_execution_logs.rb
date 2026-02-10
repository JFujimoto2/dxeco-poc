class CreateBatchExecutionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :batch_execution_logs do |t|
      t.string :job_name, null: false
      t.string :status, null: false, default: "running"
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :processed_count, default: 0
      t.integer :created_count, default: 0
      t.integer :updated_count, default: 0
      t.integer :error_count, default: 0
      t.text :error_messages

      t.timestamps
    end
  end
end
