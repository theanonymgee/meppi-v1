class CreateExchangeRates < ActiveRecord::Migration[7.1]
  def change
    create_table :exchange_rates do |t|
      t.references :country, null: false, foreign_key: true
      t.decimal :rate_official
      t.decimal :rate_black_market
      t.decimal :rate_used
      t.date :date
      t.string :source

      t.timestamps
    end
  end
end
