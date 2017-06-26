# IMPORTANT: в качесвте ключей для хешей, которые пойдут в БД, всегда используйте строки. Во избежание путаницы.
class UserProfile::PropertyCalculator
  include ChildrenCalculator

  # Вычисляет пол пользователя по историческим данным
  # @param user [User]
  # @return String – m|f
  def calculate_gender(user)
    score = { male: 0, female: 0 }
    ProfileEvent.where(user_id: user.id, industry: ['fashion', 'cosmetic'], property: 'gender').each do |event|
      if event.value == 'm'
        score[:male] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
      end
      if event.value == 'f'
        score[:female] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
      end
    end
    return nil if score[:male] == score[:female]
    return 'm' if score[:male] > score[:female]
    return 'f' if score[:male] < score[:female]
  end


  # Рассчитывает вероятные размеры одежды по типам одежды
  # @param user User
  # @return Hash | nil
  def calculate_fashion_sizes(user)
    wear_sizes = {}
    score = {}

    # Заполняем хеш сырыми данными
    # Не забываем, что поле value строковое и его нужно приводить к целым числам
    ProfileEvent.where(user_id: user.id, industry: ['fashion']).where('property like $$size_%$$').each do |event|
      wear_type = event.property.gsub('size_', '')
      size = event.value
      score[wear_type] = {} unless score.key?(wear_type)
      score[wear_type][size] = 0 unless score[wear_type].key?(size)
      score[wear_type][size] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # Запоминаем только размеры, а не их вероятность.
    # На выходе что-то вроде: {'shoe' => [38, 39], 'coat' => [33, 35]}
    score.each do |wear_type, sizes|
      median = sizes.map { |k, v| v }.max / 2.0
      selected_sizes = sizes.select { |k,v| v >= median }.map { |k,v| k.to_i }.sort
      wear_sizes[wear_type] = selected_sizes unless selected_sizes.empty?
    end

    wear_sizes.empty? ? nil : wear_sizes
  end




  # Рассчитывает тип и состояние волос покупателя
  # @param user User
  # @return Hash | nil
  def calculate_hair(user)
    score = {hair_type: {}, hair_condition: {}}

    # Заполняем хеш сырыми данными
    # Не забываем, что поле value строковое и его нужно приводить к целым числам
    ProfileEvent.where(user_id: user.id, industry: 'cosmetic').where(property: ['hair_type', 'hair_condition']).each do |event|
      score[event.property.to_sym][event.value] = 0 unless score[event.property.to_sym].key?(event.value)
      score[event.property.to_sym][event.value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    hair = {}
    hair[:type] = score[:hair_type].sort_by{ |k, v| v }.reverse.first[0] if score[:hair_type].any?
    hair[:condition] = score[:hair_condition].sort_by{ |k, v| v }.reverse.first[0] if score[:hair_condition].any?

    hair.empty? ? nil : hair
  end

  # Подсчитывает вероятность аллергии для косметики и FMCG
  # @param user [User]
  # @return Boolean | nil
  def calculate_allergy(user)
    sum = 0
    ProfileEvent.where(user_id: user.id, industry: ['cosmetic', 'fmcg']).where(property: 'hypoallergenic').each do |event|
      # Учитываем только корзины и покупки
      sum += event.carts.to_i * 2 + event.purchases.to_i * 5
    end
    # Абстрактный порог в 10 – тогда считаем, что аллергия есть
    sum >= 10 ? true : nil
  end

  # Рассчитывает тип и состояние кожи по частям тела человека.
  # Структура возвращаемого хеша:
  # skin = {
  #   'body' => { 'type' => ['normal', 'oily'], condition: ['damaged', 'tattoo'] },
  #   'hand' => { 'type' => ['dry'], condition: ['normal'] },
  #   'leg'  => { 'type' => ['common'] },
  # }
  # @param user User
  # @return Hash | nil
  def calculate_skin(user)

    score = {}

    # Заполняем хеш сырыми данными
    # Ожидаемая конструкция для расчетов
    # score = {
    #   'body' => {
    #     'type' => { 'normal' => 4, 'oily' => 7 },
    #     'condition' => { 'damaged' => 1, 'tattoo' => 7 }
    #   },
    #   'hand' => {
    #     'type' => { 'normal' => 3, 'oily' => 7 },
    #     'condition' => { 'damaged' => 1, 'tattoo' => 7 },
    #   },
    #   'leg' => {
    #     'condition' => { 'damaged' => 3 }
    #   }
    # }
    ProfileEvent.where(user_id: user.id, industry: 'cosmetic').where('property like $$skin_%$$').each do |event|

      # Часть тела и свойство (состояние или тип кожи)
      property_type, body_part = event.property.gsub('skin_', '').split('_', 2)
      value = event.value

      # Создаем характеристики
      score[body_part] = {} unless score.key?(body_part)
      score[body_part][property_type] = {} unless score[body_part].key?(property_type)
      score[body_part][property_type][value] = 0 unless score[body_part][property_type].key?(value)
      score[body_part][property_type][value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # Запоминаем только значения, а не их вероятность.
    #
    skin = {}
    score.each do |body_part, properties|
      properties.each do |property, values|
        median = values.map { |k, v| v }.max / 2.0
        selected_values = values.select { |k,v| v >= median }.map { |k,v| k }.sort
        if selected_values.any?
          skin[body_part] = {} unless skin.key?(body_part)
          skin[body_part][property] = selected_values
        end
      end
    end

    skin.empty? ? nil : skin
  end

  # Расчитывает ногти
  # @param user [User]
  # @return [Hash | nil]
  def calculate_nail(user)

  end

  # Расчитывает парфюмерию
  # @param user [User]
  # @return [Hash | nil]
  def calculate_perfume(user)
    perfumes = {}
    score = {aroma: {}}

    # Заполняем хеш сырыми данными
    # В будущем, property может быть массивом, see #calculate_hair
    ProfileEvent.where(user_id: user.id, industry: 'cosmetic', property: 'perfume_aroma').each do |event|
      key = event.property.gsub('perfume_', '').to_sym
      score[key][event.value] = 0 unless score[key].key?(event.value)
      score[key][event.value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.reject { |k,v| v.nil? || v.empty? }.blank?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    score.each do |perfume, values|
      median = values.map { |k, v| v }.max / 2.0
      selected = values.select { |k,v| v >= median }.map { |k,v| k }.sort
      perfumes[perfume.to_s] = selected unless selected.empty?
    end

    perfumes
  end



  # Определяет возможные марки автомобиля
  # @param user User
  # @return Hash | nil
  def calculate_compatibility(user)
    compatibilities = {}
    score = {}

    # Заполняем хеш сырыми данными
    ProfileEvent.where(user_id: user.id, industry: 'auto').where('property like $$compatibility_%$$').each do |event|
      compatibility = event.property.gsub('compatibility_', '')
      value = event.value
      score[compatibility] = {} unless score.key?(compatibility)
      score[compatibility][value] = 0 unless score[compatibility].key?(value)
      score[compatibility][value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # На выходе что-то вроде: {'brand' => ['BMW', 'Audi'], 'model' => ['300', 'Aveo']}
    score.each do |compatibility, values|
      median = values.map { |k, v| v }.max / 2.0
      selected = values.select { |k,v| v >= median }.map { |k,v| k }.sort
      compatibilities[compatibility] = selected unless selected.empty?
    end

    compatibilities.empty? ? nil : compatibilities
  end

  # Определяет список VIN номеров
  # @param user User
  # @return Hash | nil
  def calculate_vds(user)
    score = {}

    # Заполняем хеш сырыми данными
    ProfileEvent.where(user_id: user.id, industry: 'auto', property: 'vds').each do |event|
      value = event.value
      score[value] = 0 unless score.key?(value)
      score[value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # На выходе массив VDS
    # @param user User
    # @return Hash | nil
    median = score.map { |k, v| v }.max / 2.0
    selected = score.select { |k,v| v >= median }.map { |k,v| k }.sort

    selected.empty? ? nil : selected
  end




  # Определяет список животных
  def calculate_pets(user)
    properties = ProfileEvent.where(user_id: user.id, industry: 'pets').map { |x| Hash[x.value.split(';').map { |y| y.split(':') }].merge('score' => (x.views.to_i + x.carts.to_i * 2 + x.purchases.to_i * 5)) }.sort_by { |x| x.size }.reverse
    selected = []

    # Проверяет схожесть записей
    def _similar(a, b)
      return false if a['type'] != b['type']
      return false if a['breed'].present? && b['breed'].present? && a['breed'] != b['breed']
      return false if a['size'].present? && b['size'].present? && a['size'] != b['size']
      return false if a['age'].present? && b['age'].present? && a['age'] != b['age']
      true
    end

    while property = properties.pop
      index = selected.index { |x| _similar(x, property) }
      if index.nil?
        selected << property
      else
        selected[index]['breed'] = property['breed'] if property['breed'].present? && selected[index]['breed'].nil?
        selected[index]['age'] = property['age'] if property['age'].present? && selected[index]['age'].nil?
        selected[index]['size'] = property['size'] if property['size'].present? && selected[index]['size'].nil?
        selected[index]['score'] += property['score']
      end
    end

    # Если в выбранных животных скоринг меньше среднего, то их убираем
    selected = selected.select { |x| x['score'] >= selected.inject(0) { |sum, y| sum + y['score'] }.to_f / selected.size } if selected.any?

    return selected.any? ? selected : nil

  end


  # Рассчитывает ювелирные особенности покупателя
  # Считаем, что у человека предпочтения не конкретно к золотым кольцам или золотым браслетам,
  # а к цвету, металлу и камням, независимот от типа украшения
  def calculate_jewelry(user)

    score = {}

    properties = ProfileEvent.where(user_id: user.id, industry: 'jewelry').map { |x| {property: x.property, value: x.value, score: (x.views.to_i + x.carts.to_i * 2 + x.purchases.to_i * 5)} }

    if properties.any?

      if properties.select { |x| x[:property] == 'metal' }.any?
        score['metal'] = properties.select { |x| x[:property] == 'metal' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'color' }.any?
        score['color'] = properties.select { |x| x[:property] == 'color' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'gem' }.any?
        score['gem'] = properties.select { |x| x[:property] == 'gem' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'gender' }.any?
        score['gender'] = properties.select { |x| x[:property] == 'gender' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'ring_size' }.any?
        score['ring_size'] = properties.select { |x| x[:property] == 'ring_size' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'bracelet_size' }.any?
        score['bracelet_size'] = properties.select { |x| x[:property] == 'bracelet_size' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

      if properties.select { |x| x[:property] == 'chain_size' }.any?
        score['chain_size'] = properties.select { |x| x[:property] == 'chain_size' }.sort { |a,b| a[:score] <=> b[:score] }.last[:value]
      end

    end

    score.keys.any? ? score : nil
  end


end
