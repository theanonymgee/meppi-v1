class CreatePhones < ActiveRecord::Migration[7.1]
  def change
    create_table :phones do |t|
      t.string :brand
      t.string :model
      t.text :url
      t.text :image_url
      t.string :announced
      t.string :released
      t.string :display_size
      t.string :display_type
      t.string :display_resolution
      t.string :chipset
      t.string :cpu
      t.string :gpu
      t.string :ram
      t.text :storage
      t.text :main_camera
      t.text :selfie_camera
      t.text :battery
      t.text :os
      t.text :weight
      t.text :dimensions
      t.text :price
      t.text :specs_json
      t.datetime :scraped_at

      t.timestamps
    end
  end
end
