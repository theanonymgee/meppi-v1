class CreateChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :channels do |t|
      t.references :country, null: false, foreign_key: true
      t.string :name
      t.string :channel_type # Renamed from 'type' to avoid STI conflict
      t.text :url
      t.boolean :active

      t.timestamps
    end
  end
end
