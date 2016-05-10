Document.ready? do
  if Element.find('body.user_products').size > 0
    # 非表示ボタン
    Element.find('.ignore.button').on('click') do |event|
      product_id = event.current_target['data-product-id']
      form = event.current_target.parent.find('.edit_user_product')
      params = {'type_name' => 'shelf', 'format' => 'json'}
      payload = params.map{|k, v| "#{k}=#{`encodeURIComponent(#{v})`}"}.join('&')

      confirm('タグ付けした商品一覧からこの商品を削除します。') do
        HTTP.delete(form['action'], :payload => payload) do |response|
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
