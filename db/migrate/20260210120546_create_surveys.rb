class CreateSurveys < ActiveRecord::Migration[8.1]
  def change
    create_table :surveys do |t|
      t.string :title, null: false
      t.string :survey_type, null: false, default: "account_review"
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "draft"
      t.datetime :sent_at
      t.datetime :deadline

      t.timestamps
    end

    add_index :surveys, :status
  end
end
