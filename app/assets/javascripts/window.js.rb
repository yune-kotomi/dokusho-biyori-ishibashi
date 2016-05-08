def confirm(message)
  if (`window.confirm(#{message})`)
    yield
  end
end

def u(value)
  `encodeURIComponent(#{value})`
end
