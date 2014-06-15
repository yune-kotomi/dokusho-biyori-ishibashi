class CreateUserProducts < ActiveRecord::Migration
  def self.up
    create_table :user_products do |t|
      t.integer :user_id
      t.integer :product_id
      t.string :type_name, :default => "search" #search, shelf, ignore
      t.text :tags_json, :default => "[]"

      t.timestamps
    end
  end

  def self.down
    drop_table :user_products
  end
end
