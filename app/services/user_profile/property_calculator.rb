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

  # Рассчитывает детей покупателя
  # Структура возвращаемого массива:
  # [
  #   { age: {min: 0.25, max: 2}, gender: 'm' }
  #   { age: {min: 0.5} }
  #   { age: {max: 2} }
  #   { gender: 'f' }
  # ]
  # @param user User
  # @return Hash[]
  def calculate_children(user)

    genders_raw_data = {'m' => {}, 'f' => {}, 'u' => {} }
    kids = []

    ProfileEvent.where(user_id: user.id, industry: 'child', property: 'age').each do |event|

      age_min, age_max, gender = event.value.split('_', 3)
      gender = 'u' unless %w(m f).include?(gender)

      # TODO: не совсем правильный подсчет. Нужно разбить минимум и максимум по интервалу и суммировать их

      if age_min.present? || age_max.present?


        # Если не указана одна из границ, определяем ее как вдвое больше/меньше от присутствующей
        age_min = age_min.to_f if age_min.present?
        age_max = age_max.to_f if age_max.present?

        age_min = age_max / 2.0 unless age_min.present?
        age_max = age_min * 2.0 unless age_max.present?

        # Костыль: У MyToys бывает максимальный возраст в 178956970, поэтому делаем дополнительную проверку
        # И бывают еще отрицательные возрасты.
        age_min = 0 if age_min < 0
        age_max = 0 if age_max < 0
        age_min = 0 if age_min  > 20
        age_max = 16 if age_max > 20

        # Приводим возраст к целочисленным индексам. Так как возраст кратен 0.25, умножаем его на 4, чтобы получить
        # целый индекс для будущих массивов
        age_min = (age_min * 4).to_i
        age_max = (age_max * 4).to_i

        # Расчетная числовая оценка
        score = event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5

        # Формируем векторы оценок по возрастам
        (age_min..age_max).map do |x|
          if genders_raw_data[gender].key?(x)
            genders_raw_data[gender][x] += score
          else
            genders_raw_data[gender][x] = score
          end
        end

      else

        # Возраста нет, пытаемся определить только пол

      end

    end

    # Для каждого пола убираем низкоприоритетные возрасты, оставляя отрезки
    genders_raw_data.keys.each do |_gender|
      if genders_raw_data[_gender].any?
        genders_raw_data[_gender] = genders_raw_data[_gender].sort
        median = genders_raw_data[_gender].map { |x| x[1] }.sum / genders_raw_data[_gender].count.to_f
        genders_raw_data[_gender] = genders_raw_data[_gender].map { |x| x[1] > median ? x : nil }.uniq

        # Делим на отрезки
        genders_raw_data[_gender] = genders_raw_data[_gender].chunk { |x| x.nil? }.select { |x| x[0] == false }.map { |x| x[1] }
      end
    end

    # Формируем список детей
    genders_raw_data.each do |gender, parts|
      parts.each do |element|
        kid = { gender: gender }
        if element.any?
          if element.length == 1
            kid[:age_min] = element.first[0].to_f / 4.0
            kid[:age_max] = element.first[0].to_f / 4.0
          else
            kid[:age_min] = element.sort.first[0] / 4.0
            kid[:age_max] = element.sort.reverse.first[0].to_f / 4.0
          end
        end
        kids << kid
      end
    end

    kids

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


end