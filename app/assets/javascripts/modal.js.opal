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
