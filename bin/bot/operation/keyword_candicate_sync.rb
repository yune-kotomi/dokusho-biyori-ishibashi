# 商品テーブルから筆者情報を同期
Product.where(:category => 'books').flat_map(&:authors).uniq.compact.each do |keyword|
  words = keyword.split(/[ 　・:：]/)

  KeywordCandicate.transaction do
    if KeywordCandicate.where(:value => keyword).count == 0
      KeywordCandicate.new(
        :value => keyword,
        :elements => words
      ).save
    end
  end
end
