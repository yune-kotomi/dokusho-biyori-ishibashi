module ApplicationHelper
  def link_to_user(user, label = nil)
    if user.blank?
      return "ゲスト"
    else
      label = user.nickname if label.nil?
      return link_to(
        label,
        :controller => :users,
        :action => :show,
        :domain_name => user.domain_name,
        :screen_name => user.screen_name
      )
    end
  end

    #「著者」「アーティスト」などの使い分け語を返す
  def author_label(catalog)
    label = ''
    case catalog.downcase
      when 'books'
        label = '著者'

      when 'music'
        label = 'アーティスト'

      when 'dvd'
        label = '出演/製作'

      else
        label = '著者/アーティスト'

    end

    return label
  end

  #「出版社」「メーカー」
  def maker_label(catalog)
    label = ''
    case catalog.downcase
      when 'books'
        label = '出版社'

      when 'music', 'dvd'
        label = 'レーベル'

      else
        label = 'メーカー'

    end

    return label
  end

  #時刻表示
  def display_time(product)
    format = '%Y/%m'
    if product.a_release_date_fixed
      format = '%Y/%m/%d'
    end

    product.release_date.strftime(format) if product.release_date.present?
  end

  def countdown(src)
    if src.present?
      today = Time.now.beginning_of_day
      days = ((src.beginning_of_day - today)/(3600*24)).ceil

      if days > 0
        content_tag(:span, :class => 'countdown') { "あと#{days}日" }
      else
        ''
      end
    else
      ''
    end
  end

  def srcset(asset, range)
    ext = File.extname(asset)
    base = File.basename(asset, ext)

    range.
      reject{|i| i == 1 }.
      map{|i| ["#{base}@#{i}x#{ext}", "#{i}x"] }.to_h.
      tap{|t| t[asset] = '1x' }.
      map{|k, v| "#{asset_path(k)} #{v}" }.
      join(', ')
  end
end
