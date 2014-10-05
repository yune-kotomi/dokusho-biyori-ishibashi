def confirm(message)
  if (`window.confirm(#{message})`)
    yield
  end
end
