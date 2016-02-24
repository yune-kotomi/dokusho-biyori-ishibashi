class RemoveProductTitle < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        remove_column :products, :title
      end

      r.down do
        add_column :products, :title, :string
        Product.transaction do
          Product.find_each do |product|
            product.update_attribute(:title, product.a_title || product.r_title)
          end
        end
      end
    end
  end
end
