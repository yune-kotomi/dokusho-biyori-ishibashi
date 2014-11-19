class UserKeyword < ActiveRecord::Base
  belongs_to :user
  belongs_to :keyword

  after_save :initial_create_user_products
  before_destroy :remove_user_products

  private
  def initial_create_user_products
    keyword.keyword_products.each do |keyword_product|
      UserProduct.transaction do
        if user.user_products.where(:product_id => keyword_product.product_id).count == 0
          user.user_products.create(:product_id => keyword_product.product_id)
        end
      end
    end
  end

  def remove_user_products
    keyword.keyword_products.each do |keyword_product|
      UserProduct.transaction do
        user.user_products.where(:product_id => keyword_product.product_id, :type_name => 'search').each {|user_product| user_product.destroy }
      end
    end
  end
end
