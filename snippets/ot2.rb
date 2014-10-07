shop = Shop.find(289);

File.open('onlinetours2.csv', 'w') do |file|
  File.open('onlinetours.csv', 'r').each_line do |line|
    if line.split(',')[2] == '0'
      user_id = line.split(',')[0]
      user = User.find(user_id)
      a = shop.actions.where(user_id: user_id).order('timestamp DESC').first

      i = a.try(:item)
      if i.present? && i.locations[0].present?
        # Найти живые товары для города юзера
        items = shop.items.available.in_locations(i.locations)

        # Выбрать из них 3-10
        items = items.order('RANDOM()').last(rand(8) + 3)

        # Показать все в том же формате

        line_splitted = line.split(',')
        line_new = [line_splitted[0], line_splitted[1], items.count, items.map(&:id).join(';'), items.map(&:uniqid).join(';')].join(',')
        puts line_new

        file.puts(line_new)
      else
        file.puts(line)
      end
    else
      file.puts(line)
    end
  end
end