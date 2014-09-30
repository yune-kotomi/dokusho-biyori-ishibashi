# modal表示・クローズ処理
Document.ready? do
  Element.find('.button[data-modal]').on('click') do |event|
    id = event.current_target['data-modal']
    dialog = Element.find("##{id}")
    dialog.fade_in

    false
  end

  Element.find('.product.modal .button.close').on('click') do |event|
    button = event.current_target
    dialog = button.parents.map{|parent| parent if parent.has_class?('modal') }.compact.first
    dialog.fade_out

    false
  end
end
