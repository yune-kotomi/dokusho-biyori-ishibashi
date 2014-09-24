Document.ready? do
  if Element.find('body.users').size > 0
    Element.find('.product-list>li a.list-item').each do |card|
      card.on('click') do
        ean = card['data-ean']
        dialog = Element.find("#product-#{ean}")
        dialog.fade_in

        dialog.find('.close-button').on('click') do
          dialog.fade_out
          false
        end

        false
      end
    end
  end
end
