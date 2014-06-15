class Product < ActiveRecord::Base
  has_many :keyword_products
  has_many :user_products
end
