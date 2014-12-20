logger = Rails.logger

begin
# 使用されていないキーワードを削除
Keyword.transaction do
  Keyword.where("not id in (select distinct keyword_id from user_keywords)").each do |k|
    k.destroy
  end
end

# 外部APIコール
Keyword.all.each do |keyword|
  # Amazon
  (1..10).each do |page|
    logger.debug "Amazon: #{keyword.inspect}"
    pages, products = keyword.amazon_search(page)
    sleep 1
    break if page == pages || products.blank?
    break if products.find{|product| product.a_release_date < 1.month.ago }.present?
  end

  # 楽天ブックス
  (1..10).each do |page|
    logger.debug "楽天ブックス: #{keyword.inspect}"
    pages, products = keyword.rakuten_search(page)
    sleep 1
    break if page == pages || products.blank?
    break if products.find{|product| product.r_release_date < 1.month.ago }.present?
  end

  GC.start
end

# Groongaにて検索、カレンダー更新
Keyword.all.each do |keyword|
  hit_ids = []

  # ヒットした商品IDを収集
  (1..10).each do |page|
    logger.debug "Groonga: #{keyword.value}(#{keyword.id})"
    next_page, products = keyword.search(page)
    ids = products.map{|product| product.id}
    hit_ids.push(ids)

    break unless next_page
  end
  hit_ids = hit_ids.flatten

  # 現在キーワードに結びついているIDを収集
  exists_ids = keyword.keyword_products.map{|kp| kp.product_id}

  KeywordProduct.transaction do
    #加わった物
    (hit_ids - exists_ids).each do |id|
      logger.debug "#{keyword.value}: 追加 #{id}"
      keyword.keyword_products.create(:product_id => id)
    end

    #外れた物
    (exists_ids - hit_ids).each do |id|
      logger.debug "#{keyword.value}: 削除 #{id}"
      keyword.keyword_products.where(:product_id => id).each{|kp| kp.destroy}
    end
  end

  GC.start
end

# ユーザのカレンダーへの結びつけ
User.all.each do |user|
  UserProduct.delete_all(:type_name => 'search', :user_id => user.id)
  user.user_keywords.each do |user_keyword|
    UserProduct.transaction do
      user_keyword.keyword.keyword_products.each do |keyword_product|
        if user.user_products.where(
            :product_id => keyword_product.product_id,
            :type_name => ['search', 'ignore']
          ).count == 0
          logger.debug "User #{user.id}: 追加: #{keyword_product.product_id}"
          user.user_products.create(
            :product_id => keyword_product.product_id,
            :type_name => 'search'
          )
        end
      end
    end

    GC.start
  end
end

# 発売日が未確定で自動検索にて更新されなかった商品情報を更新
products = Product.
  where(:a_release_date_fixed => false).
  where("updated_at < ?", 1.day.ago).
  where("a_release_date between ? and ?", 2.months.ago, 1.month.from_now)
products.each do |product|
  begin
    product.update_with_amazon
  rescue Amazon::RequestError
    # do nothing
  end
  product.update_with_rakuten_books
  product.save
  sleep 1
end

#未更新の古い商品情報を更新
products = Product.
  where("updated_at < ?", 1.week.ago).
  order("updated_at").
  limit(2000)
products.each do |product|
  begin
    product.update_with_amazon
  rescue Amazon::RequestError
    # do nothing
  end
  product.update_with_rakuten_books
  product.save
  sleep 1
end

rescue => e
  logger.error e.inspect
  logger.error e.backtrace
end
