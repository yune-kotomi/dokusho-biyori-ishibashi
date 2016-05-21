require 'cgi'

# grep -h "<abstract>" jawiki-latest-abstract* |grep '漫画作品'>comic_src.txt

open(ARGV[1], 'w') do |f|
  open(ARGV[0]).read.split("\n").
    map{|s| s.gsub(/<.?abstract>/,'') }.
    map{|s| CGI.unescapeHTML(s) }.
    map{|s| s.gsub(/[(（].+[)）]/, '') }.
    map{|s| s.split(/[』」 　]/).first }.
    map{|s| s.sub(/[『「]/, '') }.
    map{|s| s.split(/は、.+の.+作品/).first }.
    uniq.compact.
    map{|s| if s.include?('漫画作品'); s.split(/と?は.+漫画/).first; else; s; end }.
    each{|s| f.puts s }
end
