class UserProfile::PropertyCalculator


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


end