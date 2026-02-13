class CreateTelcoDevicePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :telco_device_prices do |t|
      t.references :price, null: false, foreign_key: true
      t.references :telco_plan, null: false, foreign_key: { to_table: :telco_plans }
      t.decimal :device_price_local
      t.decimal :monthly_installment
      t.decimal :total_cost_24m_local
      t.decimal :effective_device_price
      t.text :notes

      t.timestamps
    end
  end
end
