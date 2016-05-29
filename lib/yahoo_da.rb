require 'open-uri'

module YahooDA
  class Parser
    def initialize(config)
      @config = config
    end

    def parse(src)
      url = "http://jlp.yahooapis.jp/DAService/V1/parse?appid=#{@config[:app_id]}&sentence=#{CGI.escape(src)}"
      data = open(url).read
      Tree.new(data)
    end
  end

  class Tree
    attr_reader :src
    attr_reader :chunks

    def initialize(src)
      doc = Nokogiri::XML(src)
      @chunks = doc.search('ResultSet/Result/ChunkList/Chunk').map{|e| Chunk.new(e, self)}
    end

    def sentence
      chunks.flat_map(&:tokens).map(&:surface).join
    end
  end

  class Chunk
    attr_reader :index
    attr_reader :tree
    attr_reader :tokens

    def initialize(element, tree)
      @index = element.search('Id').text.to_i
      @tree = tree
      @tokens = element.search('Morphem').map{|e| Token.new(e, self) }
      @link = element.search('Dependency').text.to_i
    end

    def link
      @tree.chunks.find{|c| c.index == @link }
    end

    def inspect
      "Chunk: #{surfaces}"
    end

    def features
      @tokens.flat_map(&:features)
    end

    def surfaces
      @tokens.map(&:surface)
    end

    # 与えたリスト中の語が含まれているかどうか
    def contains?(list)
      target = self.features
      list.find{|e| target.find{|t| t.include?(e) }.present? }.present?
    end
  end

  class Token
    attr_reader :surface
    attr_reader :features
    attr_reader :chunk

    def initialize(element, chunk)
      @chunk = chunk

      @surface = element.search('Surface').text
      @features = element.search('Feature').text.split(',')
    end

    def inspect
      "Token: #{@surface}"
    end

    def position
      tokens = chunk.tree.chunks.flat_map(&:tokens)
      before_tokens = tokens[0, tokens.index(self)]
      starts = before_tokens.map(&:surface).join.size
      ends = starts + surface.size - 1
      (starts..ends)
    end
  end
end
