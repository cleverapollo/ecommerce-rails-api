module ApplicationHelper
  def offer_report(element)
    report_tag(:offer, class: "section") {
      t = [
        tag(:br) +
        report_tag(:url)         { element.url } +
        report_tag(:price)       { element.price } +
        report_tag(:categoryId)  { element.category_id } +
        report_tag(:name)        { element.name } +
        report_tag(:description) { element.description } +
        report_tag(:typePrefix)  { element.type_prefix } +
        report_tag(:vendor)      { element.vendor } +
        report_tag(:vendorCode)  { element.vendor_code } +
        report_tag(:model)       { element.model } +
        report_tag(:currency, id: "RUR", rate: "1") +
        element.pictures.map{ |picture| report_tag(:picture) { picture } }.join.html_safe
      ]

      if element.cosmetic?
        t << report_tag(:cosmetic) {
          tag(:br) +
          report_tag(:hypoallergenic, class: "section") { element.cosmetic.hypoallergenic } +
          report_tag(:hypoallergenic, class: "section") { element.cosmetic.hypoallergenic } +
          report_tag(:hypoallergenic, class: "section") { element.cosmetic.hypoallergenic }
        }
      end

      t.join.html_safe
    }
  end

  def report_tag(name, attributes = {})
    value = block_given? ? yield : ''

    content_tag(:span, class: :tag){
      start_report_tag(name, attributes) +
      value_tag(value) +
      end_report_tag(name)
    }.concat tag(:br)
  end

  def value_tag(value)
    content_tag(:span, value, class: "value #{ rand(10) >= 5 ? 'error' : '' }")
  end

  def attribute_tag(key, value)
    content_tag(:span, class: "attribute #{ rand(10) >= 5 ? 'error' : '' }"){
      content_tag(:span, key, class: "attribute_key #{ rand(10) >= 5 ? 'error' : '' }") +
      "=\"" +
      content_tag(:span, value, class: "attribute_value #{ rand(10) >= 5 ? 'error' : '' }") +
      "\""
    }
  end

  def start_report_tag(name, attributes)
    content_tag(:span, class: :title){
      escape_once("<").html_safe +
      name +
      attributes.map{ |k,v| attribute_tag(k,v) }.join(" ").html_safe +
      escape_once(">").html_safe
    }
  end

  def end_report_tag(name)
    content_tag(:span, class: :title){
      escape_once("</").html_safe +
      name +
      escape_once(">").html_safe
    }
  end
end