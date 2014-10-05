Document.ready? do
  if Element.find('body.users').size > 0
    def split_tags(src)
      m = src.match(/^\[(.+?)\]$/)
      if m.nil?
        []
      else
        m[1].to_s.split('][')
      end
    end

    def join_tags(tags)
      if tags.empty?
        ''
      else
        "[#{tags.join('][')}]"
      end
    end

    # タグボタン
    def tag_button_click(event)
      button = event.current_target
      tag = button.find('span').text
      dialog = Modal::find_with_child(button)
      input_field = dialog.find('input[name="tags"]')
      tags = split_tags(input_field.value)

      if button.has_class?('selected')
        button.remove_class('selected')
        tags.delete(tag)
      else
        button.add_class('selected')
        tags.push(tag)
      end

      input_field.value = join_tags(tags)
    end

    Element.find('.product.modal .tag-selector li').on('click') do |e|
      tag_button_click(e)
    end

    # タグ編集ダイアログ-「更新する」
    Element.find('.product.modal .button.tags-update').on('click') do |event|
      dialog = Modal::find_with_child(event.current_target)
      product_id = dialog['data-id']
      tags = split_tags(dialog.find('input[name="tags"]').value)

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
