# coding: utf-8
class Product < ActiveRecord::Base
  has_many :keyword_products
  has_many :user_products

  before_save :serialize_attributes
  before_save :merge_data
  after_save :save_to_fts

  def update_with_amazon(data = nil)
    data = AmazonEcs.get(self.ean) if data.nil?

    ['title', 'manufacturer', 'image_medium', 'image_small', 'url', 'release_date', 'release_date_fixed'].each do |key|
      self.send("a_#{key}=", data["a_#{key}".to_sym])
    end

    self.a_authors_json = data[:a_authors].to_json
    self.category = data[:category]
  end

  def update_with_rakuten_books(data = nil)
    data = RakutenBooks.get(self.ean) if data.nil?

    ['title', 'authors', 'manufacturer', 'image_medium', 'image_small', 'url', 'release_date'].each do |key|
      self.send("r_#{key}=", data["r_#{key}".to_sym])
    end
  end

  # アクセサ
  def authors
    if a_authors_json.present?
      begin
        JSON.parse(a_authors_json)
      rescue JSON::ParserError
        []
      end
    else
      begin
        JSON.parse(r_authors)
      rescue JSON::ParserError
        []
      end
    end
  end

  def manufacturer
    a_manufacturer || r_manufacturer
  end

  def image_medium
    a_image_medium || r_image_medium
  end

  def image_small
    a_image_small || r_image_small
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
  def serialize_attributes
    self.r_authors = self.r_authors.to_json if self.r_authors.is_a?(Array)
  end

  # タイトル、発売日をマージする
  def merge_data
    self.title = a_title || r_title

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

  def save_to_fts
    table = Groonga['Products']
    record = table[self.id.to_s]
    if record.present?
      record['text'] = fulltext
      record['category'] = category
    else
      table.add(self.id.to_s, :text => fulltext, :category => category)
    end
  end

  def fulltext
    [title, authors.join("\n"), manufacturer].join("\n")
  end
end
