class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    # batch_execution_logs: インデックスが全くない
    add_index :batch_execution_logs, :created_at
    add_index :batch_execution_logs, :job_name
    add_index :batch_execution_logs, :status

    # tasks: task_type で絞り込みしているがインデックスなし
    add_index :tasks, :task_type

    # users: department でサーベイ等の絞り込みに使用
    add_index :users, :department

    # survey_responses: responded_at で回答済み判定に使用
    add_index :survey_responses, :responded_at
  end
end
