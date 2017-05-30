# http://localhost:8080/rails/mailers/errors_mailer/
class ErrorsMailerPreview < ActionMailer::Preview

  def yml_import_error_en
    shop = Shop.first
    shop.customer.language = 'en'
    ErrorsMailer.yml_import_error(shop, 'REASON')
  end

  def trigger_sign_up_ru
    shop = Shop.first
    shop.customer.language = 'ru'
    ErrorsMailer.yml_import_error(shop, 'REASON')
  end


  def yml_url_not_respond_en
    shop = Shop.first
    shop.customer.language = 'en'
    ErrorsMailer.yml_url_not_respond(shop)
  end

  def yml_url_not_respond_ru
    shop = Shop.first
    shop.customer.language = 'ru'
    ErrorsMailer.yml_url_not_respond(shop)
  end


  def yml_syntax_error_en
    shop = Shop.first
    shop.customer.language = 'en'
    ErrorsMailer.yml_syntax_error(shop, 'MESSAGE')
  end

  def yml_syntax_error_ru
    shop = Shop.first
    shop.customer.language = 'ru'
    ErrorsMailer.yml_syntax_error(shop, 'MESSAGE')
  end


  def yml_off_en
    shop = Shop.first
    shop.customer.language = 'en'
    ErrorsMailer.yml_off(shop)
  end

  def yml_off_ru
    shop = Shop.first
    shop.customer.language = 'ru'
    ErrorsMailer.yml_off(shop)
  end


  def products_import_error_en
    shop = Shop.first
    shop.customer.language = 'en'
    ErrorsMailer.products_import_error(shop, 'MESSAGE')
  end

  def products_import_error_ru
    shop = Shop.first
    shop.customer.language = 'ru'
    ErrorsMailer.products_import_error(shop, 'MESSAGE')
  end
end
