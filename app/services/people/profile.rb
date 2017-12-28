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
            indexes :children, type: 'nested', properties: { gender: { type: 'keyword', ignore_above: 1 }, birthday: { type: 'date' }, age: { type: 'float_range' } }
            indexes :cosmetic_hair, type: 'nested', properties: { condition: { type: 'keyword' }, type: { type: 'keyword' } }
            indexes :cosmetic_skin, type: 'nested', properties: Hash[%w(body hand leg).map {|t| [t, {
                type: 'nested',
                properties: {
                  type: { type: 'nested', properties: { normal: { type: 'short' }, oily: { type: 'short' } } },
                  condition: { type: 'nested', properties: { damaged: { type: 'short' }, tattoo: { type: 'short' } } },
                }
            }]}]
            indexes :cosmetic_perfume, type: 'nested', properties: {
                aroma: { type: 'nested', properties: Hash[Rees46ML::Perfume::AROMA_TYPES.map {|t| [t, { type: 'short' }] }] },
                family: { type: 'nested', properties: Hash[Rees46ML::Perfume::FAMILY_TYPES.map {|t| [t, { type: 'short' }] }] }
            }
            indexes :allergy, type: 'boolean'
            indexes :fashion_sizes, type: 'nested', properties: Hash[Rees46ML::Fashion::TYPES.map {|t| [t, {type: 'short'}]}]
            indexes :compatibility, type: 'nested', properties: { brand: { type: 'keyword' }, model: { type: 'keyword' } }
            indexes :vds, type: 'keyword'
            indexes :pets, type: 'nested', properties: { type: { type: 'keyword' }, breed: { type: 'keyword' }, size: { type: 'short' }, age: { type: 'float' }, score: { type: 'short' } }
            indexes :jewelry, type: 'nested', properties: Hash[%w(metal color gem gender).map {|t| [t, { type: 'keyword' }]}].merge(Hash[%w(ring_size bracelet_size chain_size).map {|t| [t, { type: 'float' }]}])
            indexes :realty, type: 'nested', properties: { type: { type: 'keyword' }, space: { type: 'float' } }
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

    # Находит профиль юзера
    # @return [People::Profile]
    def find(email)
      begin
        return People::Profile.repository.find(email) if email.present?
      rescue Elasticsearch::Persistence::Repository::DocumentNotFound => e
        Rails.logger.debug e
      end
      nil
    end

  end

  attr_reader :attributes

  def initialize(attributes={})
    @attributes = attributes.with_indifferent_access
  end

  def gender
    self.attributes['gender']
  end

  def jewelry
    self.attributes['jewelry']
  end

  def fashion_sizes
    self.attributes['fashion_sizes']
  end

  def compatibility
    self.attributes['compatibility']
  end

  def vds
    self.attributes['vds']
  end

  def pets
    self.attributes['pets']
  end

  def children
    self.attributes['children']
  end

  def to_hash
    @attributes
  end

  def save
    People::Profile.repository.save(self)
  end
end
