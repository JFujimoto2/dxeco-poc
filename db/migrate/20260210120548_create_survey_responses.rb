class CreateSurveyResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :survey_responses do |t|
      t.references :survey, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :saas_account, foreign_key: true
      t.string :response
      t.datetime :responded_at
      t.text :notes

      t.timestamps
    end

    add_index :survey_responses, [:survey_id, :user_id, :saas_account_id],
              unique: true, name: "idx_survey_responses_unique"
  end
end
