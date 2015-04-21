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
    value = if @content['picture'].is_a? Array
      @content['picture'].first
    else
      @content['picture']
    end
    StringHelper.encode_and_truncate(value)
  end

  def is_available
    @is_available != 'false'
  end

  # Delegate all unknown calls to new item object
  def method_missing(m, *args, &block)
    if @blank_item.respond_to? m
      @blank_item.public_send(m, *args, &block)
    else
      super
    end
  end
end
