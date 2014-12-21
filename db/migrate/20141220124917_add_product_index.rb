class AddProductIndex < ActiveRecord::Migration
  def change
    add_index :user_products, :product_id
    add_index :keyword_products, :product_id
  end
end
