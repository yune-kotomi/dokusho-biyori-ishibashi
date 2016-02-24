class AddProductsAAuthors < ActiveRecord::Migration
  def change
    add_column :products, :a_authors, :string, :array => true

    reversible do |r|
      r.up do
        Product.transaction do
          Product.where('not(a_authors_json is null)').find_each do |product|
            begin
              authors = JSON.parse(product.a_authors_json)
              product.update_attribute(:a_authors, authors)
            rescue JSON::ParserError
              # do nothing
            end
          end
        end
      end

      r.down do
        Product.transaction do
          Product.where("not(a_authors = '{}')").find_each do |product|
            product.update_attribute(:a_authors_json, product.a_authors.to_json)
          end
        end
      end
    end
  end
end
