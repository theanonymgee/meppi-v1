class CreatePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :prices do |t|
      t.integer :phone_id
      t.references :channel, null: false, foreign_key: true
      t.decimal :price_local
      t.decimal :price_usd
      t.string :price_type
      t.string :stock_status
      t.text :url
      t.date :date
      t.datetime :scraped_at

      t.timestamps
    end
  end
end
