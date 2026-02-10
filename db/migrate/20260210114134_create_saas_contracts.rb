class CreateSaasContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :saas_contracts do |t|
      t.references :saas, null: false, foreign_key: { to_table: :saases }
      t.string :plan_name
      t.integer :price_cents
      t.string :billing_cycle
      t.date :started_on
      t.date :expires_on
      t.string :vendor
      t.text :notes
      t.timestamps
    end

    remove_index :saas_contracts, :saas_id
    add_index :saas_contracts, :saas_id, unique: true
  end
end
