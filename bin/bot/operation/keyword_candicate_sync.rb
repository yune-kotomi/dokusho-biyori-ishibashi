# 商品テーブルから筆者情報を同期
Product.where(:category => 'books').flat_map(&:authors).uniq.compact.each do |keyword|
  words = keyword.split(/[ 　・:：]/)

  KeywordCandicate.transaction do
    kc = KeywordCandicate.where(:value => words.join).first_or_create do |kc|
      kc.elements = words
    end
    kc.update_attribute(:elements, words) if words.size > kc.elements.size
  end
end
