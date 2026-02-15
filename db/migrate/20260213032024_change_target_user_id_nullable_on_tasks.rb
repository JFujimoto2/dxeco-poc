class ChangeTargetUserIdNullableOnTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tasks, :target_user_id, true
  end
end
