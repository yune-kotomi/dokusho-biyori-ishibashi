class AlterProductsRAuthors < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        add_column :products, :r_authors_new, :string, :array => true

        Product.transaction do
          Product.where('not(r_authors is null)').find_each do |product|
            begin
              authors = JSON.parse(product.r_authors)
            rescue JSON::ParserError
              authors = YAML.load(product.r_authors)

              authors = authors.map do |str|
                encode = CharlockHolmes::EncodingDetector.detect(str)[:encoding]
                begin
                  str.encode("UTF-8", encode)
                rescue Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError
                  str.force_encoding('utf-8')
                end
              end if authors.is_a?(Array)
            end
            product.update_attribute(:r_authors_new, authors)
          end
        end

        rename_column :products, :r_authors, :r_authors_old
        rename_column :products, :r_authors_new, :r_authors
      end

      r.down do
        Product.transaction do
          Product.where("not(r_authors = '{}')").find_each do |product|
            product.update_attribute(:r_authors_old, product.r_authors.to_json)
          end
        end

        remove_column :products, :r_authors
        rename_column :products, :r_authors_old, :r_authors
      end
    end
  end
end
