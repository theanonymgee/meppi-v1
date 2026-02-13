class CreateCountries < ActiveRecord::Migration[7.1]
  def change
    create_table :countries do |t|
      t.string :code
      t.string :name
      t.string :currency
      t.string :exchange_source
      t.integer :priority
      t.boolean :active

      t.timestamps
    end
  end
end
