Document.ready? do
  if Element.find('body.users').size > 0
    # タグ編集ダイアログ-「更新する」
    Element.find('.product.modal .button.tags-update').on('click') do |event|
      dialog = event.current_target.parents.map{|parent| parent if parent.has_class?('modal') }.compact.first
      product_id = dialog['data-id']
      tags = dialog.find('input[name="tags"]').value.match(/^\[(.+?)\]$/)[1].split('][')

      form = Element.find('#new_user_product')
      params = {'type_name' => 'shelf', 'product_id' => product_id, 'tags' => tags.to_json, 'format' => 'json'}
      payload = params.map{|k, v| "#{k}=#{`encodeURIComponent(#{v})`}"}.join('&')
      HTTP.post(form['action'], :payload => payload) do |response|
        if response.ok?
          dialog.fade_out
        else
          alert('保存に失敗しました。')
        end
      end

      false
    end
  end
end
