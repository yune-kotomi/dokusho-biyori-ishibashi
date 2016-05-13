require 'cabocha'

module CaboChaWrapper
  class Parser
    def initialize
      @parser = CaboCha::Parser.new
    end

    def parse(src)
      tree = @parser.parse(src)
      Tree.new(tree)
    end
  end

  class Tree
    attr_reader :src
    attr_reader :chunks

    def initialize(src)
      @src = src
      @chunks = src.chunk_size.times.map {|i| Chunk.new(i, self) }
    end
  end

  class Chunk
    attr_reader :index
    attr_reader :tree
    attr_reader :tokens

    def initialize(index, tree)
      chunk = tree.src.chunk(index)
      @index = index
      @tree = tree
      @tokens = chunk.token_size.times.map {|i| Token.new(tree.src.token(chunk.token_pos + i), self) }
      @link = chunk.link
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
  end

  class Token
    attr_reader :surface
    attr_reader :features
    attr_reader :chunk

    def initialize(token, chunk)
      @chunk = chunk

      @surface = token.surface.force_encoding('utf-8')
      @features = token.feature_list_size.times.map{|i| token.feature_list(i).force_encoding('utf-8') }
    end

    def inspect
      "Token: #{@surface}"
    end
  end
end
