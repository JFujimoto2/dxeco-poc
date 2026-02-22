class AddSecurityAttributesToSaases < ActiveRecord::Migration[8.1]
  def change
    add_column :saases, :handles_personal_data, :boolean, default: false, null: false
    add_column :saases, :auth_method, :string
    add_column :saases, :data_location, :string
    add_index :saases, :auth_method
    add_index :saases, :data_location
  end
end
