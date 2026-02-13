class CreatePromotions < ActiveRecord::Migration[7.1]
  def change
    create_table :promotions do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :phone, null: false, foreign_key: true
      t.text :description
      t.decimal :discount_percent
      t.decimal :discount_amount_local
      t.string :promo_code
      t.date :valid_from
      t.date :valid_until

      t.timestamps
    end
  end
end
