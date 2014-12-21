require "digest/sha2"
require "base64"
require "date"
require "cgi"
require 'amazon/ecs'
require "open-uri"
require 'shellwords'

module AmazonEcs
  SortParams = {
    "Books" => "daterank",
    "Music" => "-orig-rel-date",
    "Classical" => "-orig-rel-date",
    "Vhs" => "-orig-rel-date",
    "DVD" => "-orig-rel-date",
    "Software" => "-release-date",
    "VideoGames" => "-releasedate",
    "KindleStore" => "daterank"
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

    category = category.capitalize
    category = "DVD" if category == "Dvd"
    category = "VideoGames" if category == "Videogames"
    category = 'KindleStore' if category == 'Kindlestore'

        #キーワードをそれぞれダブルクォートで囲む
    begin
      words = []
      Shellwords.shellwords(keyword.gsub('　', ' ')).each{|word|
        words.push('"' + word + '"')
      }
      words = words.join(' ')
    rescue ArgumentError
      words = keyword
    end

    src = Amazon::Ecs.item_search(words,
      :country => 'jp',
      :search_index => category,
      :response_group => 'ItemAttributes,Images',
      :sort => SortParams[category],
      :item_page => page
    )

    total_result = src.total_results

    ret = []
    src.items.each do |e|
      product = {}
      product[:ean] = e.get('ItemAttributes/EAN')

      if product[:ean].present?
        product[:category] = category_normalize e.get('ItemAttributes/ProductGroup')
        product[:a_title] = e.get("ItemAttributes/Title")
        product[:a_url] = e.get("DetailPageURL")

        manufacturer = e.get("ItemAttributes/Manufacturer")
        manufacturer = e.get("ItemAttributes/Publisher") if manufacturer.nil?
        product[:a_manufacturer] = manufacturer

        release_date = e.get("ItemAttributes/PublicationDate")
        if release_date.nil?
          release_date = e.get("ItemAttributes/ReleaseDate")
        end
        fixed = true

        release_date = release_date.to_s
        if release_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]$/
          fixed = false
          release_date += '-01'
        elsif release_date =~ /^[0-9][0-9][0-9][0-9]$/
          fixed = false
          release_date += '-01-01'
        end
        if release_date.blank?
          product[:a_release_date] = Time.at(0)
          product[:a_release_date_fixed] = false
        else
          release_date = Time.parse(release_date)
          product[:a_release_date] = release_date
          product[:a_release_date_fixed] = fixed
        end

        product[:a_image_medium] = e.get("MediumImage/URL")
        product[:a_image_small] = e.get("SmallImage/URL")

        product[:a_authors] = e.get_array("ItemAttributes/Author")
        product[:a_authors].push e.get_array("ItemAttributes/Artist")
        product[:a_authors].push e.get_array("ItemAttributes/Director")
        product[:a_authors].flatten!

        ret.push(product)
      end
    end

    return total_result, ret
  end

  def self.sign(query)
    sorted = query.sort
    message = ["GET", Host, Path, sorted.join("&")].join("\n")
    sign = hmac_sha256(Amazon::Ecs.options[:AWS_secret_key], message)
    return Base64.encode64(sign).chomp
  end

  IPAD = "\x36"
  OPAD = "\x5c"
  def self.hmac_sha256(key, message)
    ikey = IPAD * 64
    okey = OPAD * 64
    key.size.times do |i|
      ikey[i] = key[i] ^ ikey[i]
      okey[i] = key[i] ^ okey[i]
    end

    value = Digest::SHA256.digest(ikey + message)
    value = Digest::SHA256.digest(okey + value)
  end

  def self.category_normalize(src)
    src = src.gsub(' ', '').downcase
    src = 'books' if src == 'book'

    return src
  end
end
