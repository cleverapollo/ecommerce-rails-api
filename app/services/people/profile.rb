# User profiles
# @link https://github.com/elastic/elasticsearch-rails/blob/master/elasticsearch-persistence/README.md
class People::Profile
  class << self

    def repository
      @repository ||= Elasticsearch::Persistence::Repository.new do
        # Configure client
        client ElasticSearchConnector.get_connection

        # Set index name
        index :user_profiles

        # Set a custom document type
        type  :user

        # Specify the class to initialize when deserializing documents
        klass People::Profile

        # Configure the settings and mappings for the Elasticsearch index
        settings number_of_shards: 2 do
          mapping do
            indexes :id, type: 'keyword'
            indexes :gender, type: 'keyword', ignore_above: 1
            indexes :children, type: 'object', properties: { gender: { type: 'keyword', ignore_above: 1 }, birthday: { type: 'date' }, age: { type: 'float_range' } }
            indexes :cosmetic_hair, type: 'object', properties: { condition: { type: 'keyword' }, type: { type: 'keyword' } }
            indexes :cosmetic_skin, type: 'object', properties: Hash[%w(body hand leg).map {|t| [t, {
                type: 'object',
                properties: {
                  type: { type: 'object', properties: { normal: { type: 'short' }, oily: { type: 'short' } } },
                  condition: { type: 'object', properties: { damaged: { type: 'short' }, tattoo: { type: 'short' } } },
                }
            }]}]
            indexes :cosmetic_perfume, type: 'object', properties: {
                aroma: { type: 'object', properties: Hash[Rees46ML::Perfume::AROMA_TYPES.map {|t| [t, { type: 'short' }] }] },
                family: { type: 'object', properties: Hash[Rees46ML::Perfume::FAMILY_TYPES.map {|t| [t, { type: 'short' }] }] }
            }
            indexes :allergy, type: 'boolean'
            indexes :fashion_sizes, type: 'object', properties: Hash[Rees46ML::Fashion::TYPES.map {|t| [t, {type: 'short'}]}]
            indexes :compatibility, type: 'object', properties: { brand: { type: 'keyword' }, model: { type: 'keyword' } }
            indexes :vds, type: 'keyword'
            indexes :pets, type: 'object', properties: { type: { type: 'keyword' }, breed: { type: 'keyword' }, size: { type: 'short' }, age: { type: 'float' }, score: { type: 'short' } }
            indexes :jewelry, type: 'object', properties: Hash[%w(metal color gem gender).map {|t| [t, { type: 'keyword' }]}].merge(Hash[%w(ring_size bracelet_size chain_size).map {|t| [t, { type: 'float' }]}])
            indexes :realty, type: 'object', properties: { type: { type: 'keyword' }, space: { type: 'float' } }
          end
        end

        # Customize the serialization logic
        def serialize(document)
          serialize_node(super(document))
        end

        # Преобразует данные в формат elastic
        def serialize_node(node)
          case node
            when Array
              node.map! {|n| serialize_node(n) }
            when Hash
              node.each_pair do |k, v|
                if v.is_a?(Range)
                  # convert to Range data types
                  node[k] = { gte: v.first, lte: v.last }
                else
                  node[k] = serialize_node(v)
                end
              end
            else
              node
          end
        end

        # Customize the de-serialization logic
        def deserialize(document)
          if document['_source'].present?
            document['_source'] = deserialize_node(document['_source'])
          end
          super(document)
        end

        # Преобразует полученные данные
        def deserialize_node(node)
          case node
            when Array
              node.map! {|n| deserialize_node(n) }
            when Hash
              # convert from Range data types
              if node['gte'].present? && node['lte'].present?
                node['gte']..node['lte']
              else
                node.each_pair do |k, v|
                  node[k] = deserialize_node(v)
                end
              end
            else
              node
          end
        end

      end
    end

  end

  attr_reader :attributes

  def initialize(attributes={})
    @attributes = attributes
  end

  def to_hash
    @attributes
  end

  def save
    People::Profile.repository.save(self)
  end
end
