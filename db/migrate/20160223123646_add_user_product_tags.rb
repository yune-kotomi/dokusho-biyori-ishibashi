class AddUserProductTags < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        add_column :user_products, :tags, :string, :array => true

        UserProduct.transaction do
          UserProduct.where("not(tags_json = '[]')").find_each do |user_product|
            begin
              tags = JSON.parse(user_product.tags_json)
              user_product.update_attribute(:tags, tags)
            rescue JSON::ParserError
              # do nothing
            end
          end
        end

        remove_column :user_products, :tags_json
      end

      r.down do
        add_column :user_products, :tags_json, :string

        UserProduct.transaction do
          UserProduct.where("not(tags = '{}')").find_each do |user_product|
            user_product.update_attribute(:tags_json, user_product.tags.to_json)
          end
        end

        remove_column :user_products, :tags
      end
    end

    add_index :user_products, :tags, :using => 'gin'
  end
end
