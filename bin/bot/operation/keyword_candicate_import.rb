open(ARGV[0]).read.split("\n").each do |keyword|
  if ARGV[1] == 'people'
    words = keyword.split(/[ 　・]/)
  else
    words = [keyword]
  end

  KeywordCandicate.transaction do
    if KeywordCandicate.where(:value => keyword).count == 0
      KeywordCandicate.new(
        :value => keyword,
        :elements => words
      ).save
    end
  end
end
