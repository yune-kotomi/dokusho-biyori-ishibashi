require 'cgi'

# grep -h "<abstract>" jawiki-latest-abstract* |grep '漫画家'>author_src.txt
# grep -h "<abstract>" jawiki-latest-abstract* |grep '小説家'>>author_src.txt
# grep -h "<abstract>" jawiki-latest-abstract* |grep '作家'>>author_src.txt

open(ARGV[1], 'w') do |f|
  open(ARGV[0]).read.split("\n").
    map{|s| s.gsub(/<.?abstract>/,'') }.
    map{|s| CGI.unescapeHTML(s) }.
    map{|s| s.split(/は、?.+家/).first }.
    map{|s| s.gsub(/[(（].*[)）]?/, '') }.
    reject{|s| s.match(/[「『].+[』」]/) }.
    uniq.compact.
    each{|s| f.puts s }
end
