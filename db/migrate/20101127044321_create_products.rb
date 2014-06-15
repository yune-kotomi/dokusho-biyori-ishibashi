class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :ean
      t.string :category
      
      t.text :a_title
      t.text :a_authors_json
      t.text :a_manufacturer
      t.text :a_image_medium
      t.text :a_image_small
      t.text :a_url
      t.datetime :a_release_date
      t.boolean :a_release_date_fixed, :default => true
      
      t.text :r_title
      t.text :r_authors
      t.text :r_manufacturer
      t.text :r_image_medium
      t.text :r_image_small
      t.text :r_url
      t.datetime :r_release_date
      
      t.text :title
      t.datetime :release_date

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
