class CreateTaskPresetItems < ActiveRecord::Migration[8.1]
  def change
    create_table :task_preset_items do |t|
      t.references :task_preset, null: false, foreign_key: true
      t.string :action_type, null: false
      t.string :description, null: false
      t.references :default_assignee, foreign_key: { to_table: :users }
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
