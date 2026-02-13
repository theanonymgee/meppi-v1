class CreateDubaiBenchmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :dubai_benchmarks do |t|
      t.references :phone, null: false, foreign_key: true
      t.decimal :price_aed
      t.decimal :price_wholesale
      t.date :date
      t.datetime :scraped_at

      t.timestamps
    end
  end
end
