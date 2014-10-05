Document.ready? do
  if Element.find('body.users').size > 0
    def split_tags(src)
      src.split(']').map{|str| str.gsub(/\[|\]/, '') }
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

    Element.find('.product.modal .tag-selector li').on('click') {|e| tag_button_click(e) }

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

          # 新規追加されたタグをボタンとして追加
          exist_tags = dialog.find('.tag-selector>li>span').map{|t| t.text }
          template = Element.find('#tag-selector-template')
          (tags - exist_tags).each do |tag|
            button = template.template(:value => tag)
            button.on('click') {|e| tag_button_click(e) }
            button.append_to(Element.find('.product.modal .tag-selector'))

            # 今開いているダイアログのタグセレクタでは選択済みになっている必要がある
            dialog.find('.tag-selector>li').each {|t| t.add_class('selected') if t.find('span').text == tag }
          end
        else
          alert('保存に失敗しました。')
        end
      end

      false
    end
  end
end
