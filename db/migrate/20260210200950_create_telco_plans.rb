class CreateTelcoPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :telco_plans do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :plan_name
      t.decimal :monthly_fee_local
      t.integer :contract_months
      t.string :data_gb
      t.string :minutes
      t.boolean :active

      t.timestamps
    end
  end
end
