# modal表示・クローズ処理
Document.ready? do
  Modal.init_open_button(Element.find('.button[data-modal]'))
  Modal.init_dialog(Element.find('.modal .button.close'))
end

module Modal
  def self.find_with_child(child_element)
    child_element.parents.map{|parent| parent if parent.has_class?('modal') }.compact.first
  end

  def self.init_open_button(element)
    element.on('click') do |event|
      id = event.current_target['data-modal']
      dialog = Element.find("##{id}")

      overlay_height = [
        Element.find('body').outer_height,
        Element.find('html').outer_height
      ].max
      position = Element.find('document,body').scroll_top + 20
      dialog.css("height", "#{overlay_height}px")
      dialog.find('.modal-inner').css('top', "#{position}px")

      dialog.fade_in

      false
    end
  end

  def self.init_dialog(element)
    element.on('click') do |event|
      button = event.current_target
      dialog = Modal::find_with_child(button)
      button.parents.map{|parent| parent if parent.has_class?('modal') }.compact.first
      dialog.fade_out

      false
    end
  end
end
