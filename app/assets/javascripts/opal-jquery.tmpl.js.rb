class Element
  def template(values = {})
    `#{self}.tmpl(#{values.to_n})`
  end
end
