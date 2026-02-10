class CreateSaases < ActiveRecord::Migration[8.1]
  def change
    create_table :saases do |t|
      t.string :name, null: false
      t.string :category
      t.string :url
      t.string :admin_url
      t.text :description
      t.references :owner, foreign_key: { to_table: :users }
      t.string :status, default: "active", null: false
      t.jsonb :custom_fields, default: {}
      t.timestamps
    end

    add_index :saases, :name
    add_index :saases, :category
    add_index :saases, :status
  end
end
