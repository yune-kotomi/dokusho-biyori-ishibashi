class UpdateProductsFulltext < ActiveRecord::Migration
  def change
    Product.find_each do |product|
      Product.transaction do
        product.send(:update_fulltext)
        product.save
      end
    end
  end
end
