require "cgi"
require "open-uri"

module RakutenBooks
  Genre = {
    "books" => "001",
    "music" => "002",
    "classical" => "002",
    "dvd" => "003",
    "vhs" => "003",
    "videogames" => "006",
    "software" => "004",
    "blended" => "000"
  }

  #EANからの商品情報取得
  def self.get(ean)
    page, item = search(ean, "blended")
    return item[0]||{}
  end

  #キーワード商品検索
  def self.search(keyword, category, page = 1)
    # 空キーワードなら抜ける
    return [0, []] if keyword.blank?

    ret = []
    total_result = 0

    begin
      result = RakutenWebService::Books::Total.search(
        :keyword => keyword,
        :books_genre_id => Genre[category],
        :page => page
      ).order(:release_date => 'desc')

      total_result = result.count
      result.first(30).each do |item|
        ean = item["jan"]
        ean = item["isbn"] if ean.blank?

        manufacturer = item["publisher_name"]
        manufacturer = item["label"] if manufacturer.blank?

        author = item["author"]
        author = item["artistName"] if author.blank?

        if author.blank?
          authors = nil
        else
          authors = author.split('/')
        end

        medium_image_url = item['medium_image_url']
        medium_image_url = nil if medium_image_url == "http://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/noimage_01.gif?_ex=120x120"

        small_image_url = item['small_image_url']
        small_image_url = nil if small_image_url == "http://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/noimage_01.gif?_ex=64x64"

        begin
          release_date = item['sales_date'].
            split(//).
            map{|c| c.match(/[0-9]/) ? c : '-'}.
            join.
            sub(/\-$/, '')
          release_date += '-01' if release_date.split('-').size == 2
          release_date = Time.parse(release_date)

          ret.push(
            :ean => ean,
            :category => category,
            :r_title => item["title"],
            :r_url => item["affiliate_url"],
            :r_manufacturer => manufacturer,
            :r_release_date => release_date,
            :r_image_medium => medium_image_url,
            :r_image_small => small_image_url,
            :r_authors => authors
          )
        rescue ArgumentError => e
          # do nothing
          # 発売日が不正
          Rails.logger.debug item['sales_date']
          Rails.logger.debug e.inspect
        end
      end
    rescue => e
      Rails.logger.error e.inspect
    end

    return total_result, ret
  end
end
