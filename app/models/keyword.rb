class Keyword < ActiveRecord::Base
  has_many :keyword_products
  has_many :user_keywords

  def amazon_search(page = 1)
    pages = 0
    results = []
    products = []

    begin
      pages, results = AmazonEcs.search(value, category, page)
    rescue => e
      logger.error e
    end

    results.each do |result|
      Product.transaction do
        product = Product.where(:ean => result[:ean].to_s).first
        product = Product.new if product.nil?
        product.update_with_amazon(result)
        product.save
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
        product.update_with_rakuten_books(result)
        product.save
        products.push(product)
      end
    end

    return page, products
  end

  def search(page = 1)
    table = Groonga['Products']

    keywords = Shellwords.shellwords(value)
    ids = table.select do |r|
      grn = keywords.map{|keyword| r.text =~ keyword }
      grn.push(r.category == category)
      grn
    end.collect{|r| r.key.key }

    products = Product.where(:id => ids).
      order('release_date desc').
      offset((page - 1) * 20).
      limit(20)
    pages = (ids.size / 20.0).ceil

    [pages, products]
  end
end
