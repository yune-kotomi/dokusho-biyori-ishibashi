open(ARGV[0]) do |f|
  f.each_line do |line|
    src = JSON.parse(line)
    KeywordCandicate.new(
      :value => src['value'],
      :elements => src['elements']
    ).save
  end
end
