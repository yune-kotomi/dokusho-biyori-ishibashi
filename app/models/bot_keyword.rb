require 'yahoo_da'

class BotKeyword < ActiveRecord::Base
  belongs_to :user_keyword

  attr_reader :keyword

  RELEASE = ['発売', '発行', '刊行', 'リリース', '新刊']
  DATE = ['日']
  BEFORE = ['前', 'まえ']
  AFTER = ['後', 'あと', 'たった', '経った']
  ORDER = ['教え', '知', '通知']
  CHINESE_NUM = '零一二三四五六七八九'.split(//)
  WIDE_NUM = '０１２３４５６７８９'.split(//)
  BECOME = ['な', '成']

  def parse(message)
    parser = YahooDA::Parser.new(:app_id => Ishibashi::Application.config.yahoo_app_id)
    tree = parser.parse(message)

    @keyword = parse_keyword(tree)
    self.notify_at = parse_notify_at(tree)

    # bot用ユーザのキーワードとして登録する
    bot_user = User.find(Ishibashi::Application.config.bot_user_id)
    Keyword.transaction do
      keyword = Keyword.where(:value => @keyword, :category => 'books').first
      if keyword.blank?
        keyword = Keyword.new(:value => @keyword, :category => 'books')
        keyword.save
      end
      user_keyword = keyword.user_keywords.where(:user_id => bot_user.id).first
      if user_keyword.blank?
        user_keyword = keyword.user_keywords.create(:user_id => bot_user.id)
      end
      self.user_keyword_id = user_keyword.id
    end
  end

  def keyword_products_to_notify
    keyword = user_keyword.keyword
    today = Time.now.beginning_of_day
    keyword_products = keyword.keyword_products.includes(:product).references(:products)

    if notify_at.nil?
      keyword_products = keyword_products.
        where('products.release_date >= ? and keyword_products.created_at >= ?', today, today)
    else
      keyword_products = keyword_products.
        where('products.release_date = ?', notify_at.days.since(today))
    end

    keyword_products.
      where('products.a_release_date_fixed = ?', true).
      reject{|kp| sent_keyword_product_id.include?(kp.id) }
  end

  private
  def parse_keyword(tree)
    # 発売日を示すチャンクを探す
    release = tree.chunks.find{|c| c.contains?(RELEASE) }
    # 直接係っているチャンクがキーワードを含むフレーズの末尾
    keyword_last = tree.chunks.reverse.find{|c| c.link == release }
    # キーワードを含むフレーズ
    keyword_phrase = tree.chunks[0, keyword_last.index + 1]
    keywords = extract_keywords(keyword_phrase.flat_map(&:tokens))

    keywords.join(' ')
  end

  def extract_keywords(tokens)
    src = tokens.map(&:surface).join
    # キーワード候補
    keywords = src.chars.each_cons(2).map(&:join).
      map{|b| KeywordCandicate.where('value like ?', "#{b}%") }.flatten.
      map{|kc| [kc.value, kc.elements] }.flatten.uniq
    # キーワードマッチャを構築
    matcher = AhoCorasickMatcher.new(keywords)
    # 照合実行
    keywords = matcher.match(src)

    # キーワードの出現位置
    positions = keywords.uniq.map{|k| [k, keywords.count(k)] }.to_h.
      map do |keyword, count|
        positions = count.times.reduce(:last => 0, :pos => []) do |m|
          pos = src[m[:last], src.size].index(keyword) + m[:last]
          {:last => pos + keyword.size, :pos => [m[:pos], pos].flatten}
        end[:pos].map{|pos| (pos..pos + keyword.size - 1) }
        [keyword, positions]
      end.to_h
    # 重複して一致したキーワードから最長のものを選択
    positions = positions.select do |keyword, ranges|
      others = positions.reject{|k, v| k == keyword }.values.flatten
      ranges.select{|r| others.select{|other| other.cover?(r.min) && other.cover?(r.max) }.present? }.blank?
    end

    current = nil
    token_group = tokens.group_by do |t|
      overlapped = positions.values.flatten.find{|r| r.cover?(t.position.min) || r.cover?(t.position.max) }
      current = overlapped if overlapped.present?
      current
    end

    # キーワードに被っていないトークン
    remainings = token_group.map do |r, tokens|
      if r.nil?
        remaining = tokens
      else
        remaining = tokens.reject{|t| r.cover?(t.position.min) || r.cover?(t.position.max) }
      end
      remaining.pop if remaining.last && remaining.last.features.include?('助詞')
      remaining
    end.reject(&:blank?).map{|t| t.map(&:surface).join }

    [
      positions.keys.map do |k|
        kc = KeywordCandicate.where(:value => k).first
        if kc.present?
          kc.elements
        else
          k
        end
      end.flatten,
      remainings
    ].flatten
  end

  def parse_notify_at(tree)
    # 指示を示すチャンクを探す
    order = tree.chunks.find{|c| c.contains?(ORDER) }
    if order.present?
      order_for = tree.chunks.reverse.find{|c| c.link == order }

      case
      when order_for.contains?(BEFORE + AFTER)
        # ○日前/後が指定されている。当日通知の変形
        num = order_for.surfaces.join
        CHINESE_NUM.each_with_index{|c, i| num.gsub!(c, i.to_s) }
        WIDE_NUM.each_with_index{|c, i| num.gsub!(c, i.to_s) }

        num = num.to_i
        num = 7 if num > 7
        num = num * -1 if (order_for.features & AFTER).present?

        num

      when order_for.contains?(RELEASE), order_for.contains?(DATE)
        # 指示の対象は発売日そのもの
        case order_for.tokens.last.surface # 末尾の助詞
        when 'に', 'で'
          # 当日通知
          0
        when 'を', 'も', 'やら', 'とか', 'だの', 'くらい'
          # 情報通知
          nil
        end

      when order_for.contains?(BECOME)
        if tree.chunks.find{|c| c.link == order_for }.contains?(RELEASE)
          0
        else
          self.uncertain = true
        end

      else
        self.uncertain = true
        nil
      end
    else
      self.uncertain = true
      nil
    end
  end
end
