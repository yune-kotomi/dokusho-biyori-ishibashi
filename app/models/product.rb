# coding: utf-8
class Product < ActiveRecord::Base
  has_many :keyword_products
  has_many :user_products

  before_save :merge_data
  before_save :update_fulltext

  def update_with_amazon(data = nil)
    data = AmazonEcs.get(self.ean) if data.nil?

    if data.present?
      ['title', 'manufacturer', 'image_medium', 'image_small', 'url', 'release_date', 'release_date_fixed'].each do |key|
        self.send("a_#{key}=", data["a_#{key}".to_sym])
      end

      self.a_authors = data[:a_authors]
      self.category = data[:category]
      self.ean = data[:ean]
    end
  end

  def update_with_rakuten_books(data = nil)
    data = RakutenBooks.get(self.ean) if data.nil?

    if data.present?
      ['title', 'authors', 'manufacturer', 'image_medium', 'image_small', 'url', 'release_date'].each do |key|
        self.send("r_#{key}=", data["r_#{key}".to_sym])
      end

      self.ean = data[:ean]
      self.category = data[:category]
    end
  end

  # アクセサ
  def authors
    if a_authors.present?
      a_authors
    else
      r_authors
    end
  end

  def manufacturer
    a_manufacturer || r_manufacturer
  end

  def title
    a_title || r_title
  end

  def image_medium
    uri = a_image_medium || r_image_medium
    uri.sub('ecx.images-amazon.com', 'images-na.ssl-images-amazon.com').
      sub('http://', 'https://') if uri
  end

  def image_small
    uri = a_image_small || r_image_small
    uri.sub('ecx.images-amazon.com', 'images-na.ssl-images-amazon.com').
      sub('http://', 'https://') if uri
  end

  #関連商品を返す
  def related_products
    return @related_products unless @related_products.nil?

    keyword = keyword_products.
      map {|kp| kp.keyword if kp.keyword.present? }.
      compact.
      sort{|a, b| b.user_keywords.count <=> a.user_keywords.count }.
      first

    if keyword.present?
      ret = keyword.keyword_products.
        includes(:product).
        order("products.release_date desc").
        limit(5).
        map {|kp| kp.product unless kp.product == self }.
        compact[0, 4]
    end

    @related_products = ret
    return ret || []
  end

  private
  # 発売日をマージする
  def merge_data
    if a_release_date.present?
      if a_release_date_fixed
        self.release_date = a_release_date
      else
        if r_release_date.present?
          self.release_date = r_release_date
        else
          self.release_date = a_release_date
        end
      end
    else
      self.release_date = r_release_date
    end
  end

  def update_fulltext
    self.fulltext = ::Keyword::FTS_TARGETS.flat_map{|c| self.send(c) }.join("\n")
  end
end
