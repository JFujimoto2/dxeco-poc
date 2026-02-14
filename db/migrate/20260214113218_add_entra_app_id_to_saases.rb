class AddEntraAppIdToSaases < ActiveRecord::Migration[8.1]
  def change
    add_column :saases, :entra_app_id, :string
    add_index :saases, :entra_app_id, unique: true
  end
end
