require_relative '../../bin/bot/cabocha_wrapper'

class BotKeyword < ActiveRecord::Base
  attr_reader :keyword

  RELEASE = ['発売', '発行', '刊行', 'リリース', '新刊']
  DATE = ['日']
  BEFORE = ['前', 'まえ']
  AFTER = ['後', 'あと', 'たった', '経った']
  ORDER = ['教える', '知る', '通知', '知らせる']
  CHINESE_NUM = '零一二三四五六七八九'.split(//)
  WIDE_NUM = '０１２３４５６７８９'.split(//)
  BECOME = ['なる']

  def parse(message)
    parser = CaboChaWrapper::Parser.new
    tree = parser.parse(message)

    @keyword = parse_keyword(tree)
    self.notify_at = parse_notify_at(tree)
  end

  private
  def parse_keyword(tree)
    # 発売日を示すチャンクを探す
    release = tree.chunks.find{|c| (c.surfaces & RELEASE).present? }
    # 直接係っているチャンクがキーワードを含むフレーズの末尾
    keyword_last = tree.chunks.find{|c| c.link == release }
    # キーワードを含むフレーズ
    keyword_phrase = tree.chunks[0, keyword_last.index + 1]
    # 末尾の助詞を除いたものがキーワード
    # 全チャンクから助詞を除いたもの、でないのは文になっているタイトルを保持するため。例: 言の葉の庭
    keyword_phrase.map do |chunk|
      if chunk == keyword_last
        chunk.tokens.map{|t| t.surface unless t == chunk.tokens.last || t.features.first == '助詞' }
      else
        chunk.tokens.map(&:surface)
      end
    end.join
  end

  def parse_notify_at(tree)
    # 指示を示すチャンクを探す
    order = tree.chunks.find{|c| (c.features & ORDER).present? }
    order_for = tree.chunks.find{|c| c.link == order }

    case
    when (order_for.features & (BEFORE + AFTER)).present?
      # ○日前/後が指定されている。当日通知の変形
      num = order_for.surfaces.join
      CHINESE_NUM.each_with_index{|c, i| num.gsub!(c, i.to_s) }
      WIDE_NUM.each_with_index{|c, i| num.gsub!(c, i.to_s) }

      num = num.to_i
      num = num * -1 if (order_for.features & AFTER).present?

      num

    when (order_for.surfaces & RELEASE).present?, (order_for.surfaces & DATE).present?
      # 指示の対象は発売日そのもの
      case order_for.tokens.last.surface # 末尾の助詞
      when 'に', 'で'
        # 当日通知
        0
      when 'を', 'も', 'やら', 'とか', 'だの', 'くらい'
        # 情報通知
        nil
      end

    when (order_for.features & BECOME).present?
      if (tree.chunks.find{|c| c.link == order_for }.surfaces & RELEASE).present?
        0
      else
        self.uncertain = true
      end

    else
      self.uncertain = true
    end
  end
end
