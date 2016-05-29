class Keyword < ActiveRecord::Base
  FTS_TARGETS = [:title, :authors, :manufacturer].
    flat_map{|s| ["a_#{s}", "r_#{s}"] }.
    map(&:to_sym)

  has_many :keyword_products
  has_many :user_keywords
  after_save :initial_search

  validates :value, :presence => true

  def amazon_search(page = 1)
    pages = 0
    results = []
    products = []

    begin
      pages, results = AmazonEcs.search(value, category, page)
    rescue Amazon::RequestError
      # do nothing
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
    # なんかの間違いで空文字列が渡された場合は抜ける
    return [0, []] if value.blank?

    # クエリ組み立て
    begin
      keywords = Shellwords.shellwords(value)
    rescue ArgumentError
      keywords = [value]
    end
    # キーワードをGroongaのクエリ用にエスケープ
    keywords = keywords.map {|k| k.split(//).map{|c| ({'"' => '\\"', '\\' => '\\\\'})[c] || c }.join }.map{|k| "\"#{k}\"" }

    products = Product.where('fulltext @@ ?', keywords.join(' '))

    pages = (products.count / 20.0).ceil
    products = products.order('release_date desc').
      offset((page - 1) * 20).
      limit(20)

    [pages, products]
  end

  private
  def initial_search
    amazon_search
    pages, products = search
    products.each do |product|
      keyword_products.create(:product_id => product.id)
    end
  end
end
