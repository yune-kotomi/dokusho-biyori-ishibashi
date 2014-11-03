Document.ready? do
  if Element.find('body.keywords').size > 0
    def append_keyword(event)
      form = event.current_target.parents.map{|parent| parent if parent.has_class?('new_keyword')}.compact.first
      HTTP.post(form['action'], :payload => form.serialize) do |response|
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
      append_keyword(event)
      false
    end
  end
end
