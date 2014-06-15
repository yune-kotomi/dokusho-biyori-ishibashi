require 'groonga'
Groonga::Context.default_options = {:encoding => :utf8}
path = "#{Rails.root}/db/groonga/#{Rails.env}/"
if File.exists?("#{path}/groonga.db")
  Groonga::Database.open("#{path}/groonga.db")
else
  FileUtils.mkdir_p(path)
  Groonga::Database.create(:path => "#{path}/groonga.db")
  
  def create_table(table_name)
    Groonga::Schema.create_table(table_name, :type => :hash) do |table|
      yield(table)
    end
    Groonga::Schema.create_table(
      "#{table_name}Terms", 
      :type => :patricia_trie, 
      :normalizer => :NormalizerAuto,
      :default_tokenizer => "TokenBigram"
    ) do |table|
      table.index("#{table_name}.text")
    end
  end
  
  create_table('UserProducts') do |table|
    table.text('text')
    table.integer32('user_id')
  end
end
