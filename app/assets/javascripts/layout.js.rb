def init_footer_and_fab
  moving_footer = Element.find('main>footer')
  fixed_footer = Element.find('.mdl-layout>footer')
  page_content = Element.find('.page-content')
  main = Element.find('main')
  fab = Element.find('.right-bottom-fab')
  height = `$(window).innerHeight()`

  unless Element.find('body.welcome').empty?
    moving_footer.show
    return
  end

  if height > 667
    # 画面が大きい場合は常にフッタを固定
    moving_footer.remove
    fixed_footer.ex_resize do
      bottom = fixed_footer.outer_height + 16
      fab.css('bottom', "#{bottom}px")
    end.call
  else
    # 画面が小さい場合
    if page_content.outer_height > height - Element.find('header').outer_height
      # スクロールが必要な場合はフッタがスクロールアウトするように
      fixed_footer.remove
      moving_footer.show
      fab.css('bottom', "16px")
      Window.on(:scroll) do |e|
        bottom = `$(window).scrollTop() + $(window).innerHeight()` - moving_footer.offset.top
        if bottom >= 0
          # FAB移動
          fab.css('bottom', "#{bottom + 16}px")
        else
          fab.css('bottom', '16px')
        end
      end
    else
      # スクロール不要(本文が少ない)な場合はフッタを固定
      moving_footer.remove
      fixed_footer.ex_resize do
        bottom = fixed_footer.outer_height + 16
        fab.css('bottom', "#{bottom}px")
      end.call
    end
  end unless fixed_footer.empty?
end

Document.ready? do
  init_footer_and_fab
end
