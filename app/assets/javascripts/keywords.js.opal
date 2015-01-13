Document.ready? do
  if Element.find('body.keywords').size > 0
    def append_keyword(event)
      form = event.current_target.parents.map{|parent| parent if parent.has_class?('new_keyword')}.compact.first
      # 通信中はボタンをdisableにする
      button = form.find('.button')
      button.add_class('disabled')

      HTTP.post(form['action'], :payload => form.serialize) do |response|
        # 通信終了したのでボタンを元に戻す
        button.remove_class('disabled')

        if response.ok?
          data = response.json
          # リストにキーワード追加
          list_item = Element.parse(data['list_item'])
          form.parent.find('.keywords').append(list_item)
          # プレビューモーダル追加
          modal = Element.parse(data['modal'])
          Element.find('#preview-modal-list').append(modal)
          # 追加したキーワードのプレビューイベント
          Modal.init_open_button(list_item.find('.button[data-modal]'))
          Modal.init_dialog(modal.find('.button.close'))
          # 削除イベント
          list_item.find('.button.delete').on('click') do |event|
            delete_keyword(event)
            false
          end
          # フォームクリア
          form.find('input[type="text"]').value = ''
          button.add_class('disabled')
        else
          alert('追加に失敗しました。')
        end
      end
    end

    def delete_keyword(event)
      keyword_id = event.current_target.attr('data-id')
      confirm('このキーワードを削除します') do
        HTTP.delete("/keywords/#{keyword_id}") do |response|
          if response.ok?
            # リストから削除
            Element.find("li[data-id='#{keyword_id}']").fade_out
          else
            alert('削除に失敗しました。')
          end
        end
      end
    end

    # 既存キーワード一覧にイベントハンドラ設定
    Element.find('ul.keywords>li .button.delete').on('click') do |event|
      delete_keyword(event)
      false
    end

    # 追加ボタンにイベントハンドラ設定
    Element.find('form.new_keyword .button').on('click') do |event|
      append_keyword(event) unless event.current_target.has_class?('disabled')
      false
    end

    # textfieldでエンター
    Element.find('input[name="keyword[value]"]').on('keypress') do |event|
      false if event.which == 13
    end

    # 追加ボタンはキーワードが入力され、重複していない場合のみenable
    Element.find('input[name="keyword[value]"]').on('keyup') do |event|
      text_field = event.current_target
      form = text_field.parent.parent
      button = form.find('a.button')
      keywords = form.parent.find('.keywords .value a.button').map{|e| e.text.gsub(/\n/, '').strip }
      if text_field.value.to_s.strip == '' or keywords.include?(text_field.value)
        button.add_class('disabled')
      else
        button.remove_class('disabled')
      end

      if event.which == 13
        append_keyword(event) unless event.current_target.has_class?('disabled')
      end

      false
    end

    # ユーザ設定
    Element.find('#user-settings input[type="checkbox"]').on('change') do |event|
      form = Element.find('#user-settings')
      HTTP.post(form['action'], :payload => form.serialize) do |response|
        if response.ok?
          # do nothing
        else
          alert('設定の変更に失敗しました。')
        end
      end
    end

    Element.find('#user_private').on('change') do |event|
      # 非公開の場合のみランダムURLのチェックボックスを有効にする
      if Element.find('#user_private').is(':checked')
        Element.find('#random-url-container').remove_class('disabled')
        Element.find('#user_random_url').remove_attr('disabled')
      else
        Element.find('#random-url-container').add_class('disabled')
        Element.find('#user_random_url')['disabled'] = 'disabled'
      end
    end
  end
end
