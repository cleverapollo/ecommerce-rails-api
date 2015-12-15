require "tsort"

module Rees46ML
  class Tree
    def initialize
      @collection = {}
    end

    def each
      @collection.each{ |_, node| yield node } if block_given?
    end

    def <<(node)
      @collection[node.id] = node
    end

    def [](id)
      @collection[id]
    end

    def empty?
      @collection.empty?
    end

    def include?(v)
      @collection.values.include?(v)
    end

    def size
      @collection.keys.size
    end

    def cycles
      inverse_index.strongly_connected_components.select{ |components|
        components.size > 1
      }
    end

    def valid?
      not cycles.any?
    end

    def path_to(id)
      node = @collection[id]

      if node && node.parent_id
        path_to(node.parent_id) << id
      else
        # may be raise error?
        []
      end
    end

    private

    def inverse_index
      @collection.values.inject(InverseIndex.new) do |index, node|
        index[node.parent_id] ||= []
        index[node.id] ||= []
        index[node.parent_id] << node.id
        index
      end
    end

    class InverseIndex < Hash
      include TSort

      alias tsort_each_node each_key

      def tsort_each_child(node, &block)
        fetch(node).each(&block)
      end
    end
  end
end
