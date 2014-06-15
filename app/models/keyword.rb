require "#{Rails.root}/lib/amazon"
require "#{Rails.root}/lib/rakuten_books"

class Keyword < ActiveRecord::Base
  has_many :keyword_products
  has_many :user_keywords
  
  def amazon_search(page = 1)
    pages = 0
    results = []
    products = []
    
    begin
      pages, results = Amazon::search(value, category, page)
    rescue => e
      logger.error e
    end
    
    results.each do |result|
      Product.transaction do
        product = Product.where(:ean => result[:ean].to_s).first
        product = Product.new if product.nil?
        product.update_attributes(result)
        product.put_to_fts
        products.push(product)
      end
    end
    
    return pages, products
  end
  
  def rakuten_search(page = 1)
    pages = 0
    results = []
    products = []
        
    begin
      pages, results = RakutenBooks::search(value, category, page)
    
    rescue => e
      logger.error e
    end
    
    results.each do |result|
      Product.transaction do
        product = Product.where(:ean => result[:ean].to_s).first
        product = Product.new if product.nil?
        product.update_attributes(result)
        product.put_to_fts
        products.push(product)
      end
    end
    
    return page, products
  end
  
  def kitaguchi_search(page = 1)
    fts = Toyonaka::Application.config.groonga[:products]
    query = Yumenosora::GroongaWrapper.generate_query(value, 'fulltext') + 
      " category:#{category}"
    
    result = fts.select(
      :query => query,
      :sortby => '-release_date',
      :limit => 20,
      :offset => (page-1) * 20
    )
    
    next_page = false
    next_page = true if page * 20 < result[:total]
    
    products = []
    result[:values].each do |r|
      product = Product.find(r['_key'])
      products.push product unless product.nil?
    end
    
    return next_page, products
  end
end
