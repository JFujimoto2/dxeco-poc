class CreateTaskPresets < ActiveRecord::Migration[8.1]
  def change
    create_table :task_presets do |t|
      t.string :name, null: false
      t.string :task_type, null: false
      t.text :description

      t.timestamps
    end
  end
end
