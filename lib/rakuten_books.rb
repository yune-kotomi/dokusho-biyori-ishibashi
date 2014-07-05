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
    params = []
    ({"developerId" => Ishibashi::Application.config.rakuten[:developer_id],
      "affiliateId" => Ishibashi::Application.config.rakuten[:affiliate_id],
      "operation" => "BooksTotalSearch",
      "version" => "2009-04-15",
      "sort" => "-releaseDate",
      "outOfStockFlag" => "1",
      "field" => "0",
      "keyword" => keyword,
      "booksGenreId" => Genre[category]}).each do |key, value|

      params.push "#{key}=#{CGI::escape value}"
    end
    request_url = "http://api.rakuten.co.jp/rws/2.0/json?#{params.join "&"}"

    if defined?(OpenURI)
      #puts request_url
      src = open(request_url).read
    else
      src = AppEngine::URLFetch.fetch(request_url).body
    end

    data = JSON.parse src

    ret = []
    total_result = 0
    #データ存在チェック
    if data["Header"]["Status"] == "Success"
      #パッキング
      total_result = data["Body"]["BooksTotalSearch"]["pageCount"]
      data["Body"]["BooksTotalSearch"]["Items"]["Item"].each do |item|
        ean = item["jan"]
        ean = item["isbn"] if ean == ""

        manufacturer = item["publisherName"]
        manufacturer = item["label"] if manufacturer == ""

        author = item["author"]
        author = item["artistName"] if author == ""

        authors = [author] unless author.empty?
        authors = nil if author.empty?

        if item["mediumImageUrl"] == "http://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/noimage_01.gif?_ex=120x120"
          item.delete("mediumImageUrl")
        end

        if item["smallImageUrl"] == "http://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/noimage_01.gif?_ex=64x64"
          item.delete("smallImageUrl")
        end

        begin
          release_date = Time.parse(item["salesDate"])
          ret.push(
            :ean => ean,
            :r_title => item["title"],
            :r_url => item["affiliateUrl"],
            :r_manufacturer => manufacturer,
            :r_release_date => release_date,
            :r_image_medium => item["mediumImageUrl"],
            :r_image_small => item["smallImageUrl"],
            :r_authors => authors
          )
        rescue ArgumentError
          # do nothing
          # 発売日が不正
        end
      end
    end

    return total_result, ret
  end
end
