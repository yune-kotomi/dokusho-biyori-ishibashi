open(ARGV[0], 'w') do |f|
  KeywordCandicate.find_each do |kc|
    f.puts ({:value => kc.value, :elements => kc.elements}).to_json
  end
end
