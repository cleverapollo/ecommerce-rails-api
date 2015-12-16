require "tsort"
require "forwardable"

module Rees46ML
  class Tree
    include ActiveModel::Validations
    include Enumerable
    extend Forwardable

    validate :check_invalid_nodes
    validate :check_cycles, unless: ->{ with_invalid_parent_id.any? }

    def initialize
      @collection = {}
    end

    def_delegator :nodes, :each
    def_delegator :@collection, :[]

    def nodes
      @collection.values
    end

    def <<(node)
      @collection[node.id] = node
    end

    def cycles
      inverse_index.strongly_connected_components.select{ |c| c.size > 1 }
    end

    def with_invalid_parent_id
      nodes.select{ |node| node.parent_id.present? }.reject{ |node| self[node.parent_id].present? }
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

    def check_invalid_nodes
      with_invalid_parent_id.each do |node|
        errors.add :base, "Не удалось определить родительскую категорию для #{ node.id } - #{ node.name }"
      end
    end

    def check_cycles
      errors.add :base, "Ошибка в структуре дерева #{ cycles.join(' -> ') }" if cycles.any?
    end

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
