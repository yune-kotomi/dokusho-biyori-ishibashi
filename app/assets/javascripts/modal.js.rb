# modal表示・クローズ処理
Document.ready? do
  Modal.init_open_button(Element.find('.button[data-modal]'))
  Modal.init_dialog(Element.find('dialog'))
end

module Modal
  def self.find_with_child(child_element)
    child_element.parents.map{|parent| parent if parent.has_class?('modal') }.compact.first
  end

  def self.init_open_button(element)
    element.on('click') do |event|
      id = event.current_target['data-modal']
      dialog = Element.find("##{id}")
      `#{dialog.get(0)}.showModal()`
      false
    end
  end

  def self.init_dialog(elements)
    elements.to_a.each do |e|
      %x{
        if(!#{e.get(0)}.showModal){ dialogPolyfill.registerDialog(#{e.get(0)}) }
      }
      e.find('.close').on('click') { `#{e.get(0)}.close()` }
    end
  end
end
