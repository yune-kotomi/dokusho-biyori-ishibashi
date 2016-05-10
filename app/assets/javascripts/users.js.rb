Document.ready? do
  if Element.find('body.users').size > 0
    # 非表示ボタン
    Element.find('.ignore.button').on('click') do |event|
      product_id = event.current_target['data-product-id']
      form = Element.find('#new_user_product')
      params = {'type_name' => 'ignore', 'product_id' => product_id, 'format' => 'json'}
      payload = params.map{|k, v| "#{k}=#{`encodeURIComponent(#{v})`}"}.join('&')

      confirm('この商品を非表示にします') do
        HTTP.post(form['action'], :payload => payload) do |response|
          if response.ok?
            Element.find("#product_#{product_id}").fade_out
          else
            alert('保存に失敗しました。')
          end
        end
      end

      false
    end
  end
end
