##
# Обертка над товаром из YML.
#
class YmlItem
  # args = {
  #   id: ID товара в YML,
  #   is_available: параметр available из YML,
  #   content: XML внутри блока offer из YML,
  #   categories_resolver: объект, содержащий дерево категорий
  # }
  #
  def initialize(args)
    @uniqid = args.fetch(:id)
    @is_available = args.fetch(:is_available, true)
    @content = Hash.from_xml("<item>#{args.fetch(:content)}</item>")['item']
    @categories_resolver = args.fetch(:categories_resolver)
    # В этот объект будут делегироваться вызовы аттрибутов, которых нет у данного класса
    @blank_item = Item.new
  end

  def uniqid
    @uniqid.to_s
  end

  def price
    @content.fetch('price').to_f
  end

  def categories
    @categories_resolver[@content['categoryId']]
  end

  def name
    StringHelper.encode_and_truncate(@content['name'])
  end

  def description
    StringHelper.encode_and_truncate(@content['description'])
  end

  def url
    StringHelper.encode_and_truncate(@content['url'])
  end

  def image_url
    picture_attribute = @content['picture']
    picture_attribute = picture_attribute.first if picture_attribute.is_a? Array
    StringHelper.encode_and_truncate(picture_attribute)
  end

  def is_available
    @is_available != 'false'
  end

  def locations
    if @content['locations'].present? && @content['locations']['location'].present?
      result = { }
      @content['locations']['location'].each do |location|
        result[location['id']] = { }
        if location['price'].present?
          result[location['id']]['price'] = location['price'].to_f
        end
      end
      result
    else
      []
    end
  end

  # Delegate all unknown calls to new item object
  def method_missing(method_name, *args, &block)
    if @blank_item.respond_to? method_name
      @blank_item.public_send(method_name)
    else
      super
    end
  end
end
