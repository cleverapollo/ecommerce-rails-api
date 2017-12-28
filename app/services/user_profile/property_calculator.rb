# IMPORTANT: в качесвте ключей для хешей, которые пойдут в БД, всегда используйте строки. Во избежание путаницы.
class UserProfile::PropertyCalculator
  # include UserProfile::ChildrenCalculator

  # Вычисляет пол пользователя по историческим данным
  # @param [Number|Array] session_id
  # @return [String] – m|f
  def calculate_gender(session_id)
    score = { male: 0, female: 0 }

    # Новый метод расчета пола из кликхауса
    events = ProfileEventCl.where(industry: %w(fashion cosmetic), property: 'gender', session_id: session_id, event: %w(view cart purchase)).group(:event, :value).pluck('event, value, count(*)')
    events.each do |event|
      score[:male] += event[2] * calculate_score_for_event(event[0]) if event[1] == 'm'
      score[:female] += event[2] * calculate_score_for_event(event[0]) if event[1] == 'f'
    end

    return nil if score[:male] == score[:female]
    return 'm' if score[:male] > score[:female]
    return 'f' if score[:male] < score[:female]
  end


  # Рассчитывает вероятные размеры одежды по типам одежды
  # @param [Number|Array] session_id
  # @return Hash | nil
  def calculate_fashion_sizes(session_id)
    sizes = calculate_property_like('fashion', 'size', session_id)
    sizes = sizes.map{|k,v| {k => v.map{|v| v.to_i}}}.reduce(:merge) if sizes.present?
    sizes
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
    properties = ProfileEvent.where(user_id: user.id, industry: 'cosmetic', property: 'nail_type').map(&:attributes).collect do |x|
                   x = x.extract!("value", "views", "carts", "purchases")
                   score = (x['views'].to_i + x['carts'].to_i * 2 + x['purchases'].to_i * 5)
                   type, color = x['value'].split('_')
                   x.merge({ 'score' => score, 'type' => type, 'color' => color })
                 end

    properties = properties.sort_by{|x| x['score']}.reverse.uniq{|x| x['type']}

    calculated_data = properties.inject({}) do  |calculated_data, property|
      calculated_data[property['type']] = { 'color' => property['color'] }
      calculated_data
    end
    calculated_data.any? ? calculated_data : nil
  end

  # Расчитывает парфюмерию
  # @param user [User]
  # @return [Hash | nil]
  def calculate_perfume(user)
    perfumes = {}
    score = {aroma: {}, family: {}}

    # Заполняем хеш сырыми данными
    ProfileEvent.where(user_id: user.id, industry: 'cosmetic', property: %w(perfume_aroma perfume_family)).each do |event|
      key = event.property.gsub('perfume_', '').to_sym
      score[key][event.value] = 0 unless score[key].key?(event.value)
      score[key][event.value] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
    end

    return nil if score.reject { |k,v| v.nil? || v.empty? }.blank?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    score.each do |perfume, values|
      median = values.map { |k, v| v }.max.to_i / 2.0
      selected = values.select { |k,v| v >= median }.map { |k,v| k }.sort
      perfumes[perfume.to_s] = selected unless selected.empty?
    end

    perfumes
  end



  # Определяет возможные марки автомобиля
  # @param [Number|Array] session_id
  # @return Hash | nil
  def calculate_compatibility(session_id)
    calculate_property_like('auto', 'compatibility', session_id)
  end

  # Определяет список VIN номеров
  # @param [Number|Array] session_id
  # @return Hash | nil
  def calculate_vds(session_id)
    calculate_by_property('auto', 'vds', session_id)
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

  def calculate_realty(user)
    properties = ProfileEvent.where(user_id: user.id, industry: 'real_estate').map(&:attributes).collect do |x|
                   x = x.extract!("property", "value", "views", "carts", "purchases")
                   score = (x['views'].to_i + x['carts'].to_i * 2 + x['purchases'].to_i * 5)
                   type, action = x['property'].split('_')
                   x.merge({'score' => score, 'type' => type, 'action' => action})
                 end

    properties = properties.sort_by{|x| x['score']}.reverse.uniq{|x| x['action']}

    calculated_data = properties.inject({}) do  |calculated_data, property|
      calculated_data[property['action']] = { type: property['type'], space: property['value'] }
      calculated_data
    end
    calculated_data.any? ? calculated_data : nil
  end

  # Рассчитывает детей покупателя
  # Структура возвращаемого массива:
  # [
  #   { age: 0.25..2, gender: 'm' }
  #   { gender: 'f' }
  # ]
  # @param [Number] session_id
  # @return Hash[]
  def calculate_children(session_id)

    genders_raw_data = {'m' => {}, 'f' => {}, 'u' => {} }
    kids = []

    events = ProfileEventCl.where(industry: 'child', session_id: session_id, event: %w(view cart purchase), property: 'age').group(:event, :value, :date).pluck('event, value, count(*), date')
    events.each do |event|
      age_min, age_max, gender = event[1].split('_', 3)
      gender = 'u' unless %w(m f).include?(gender)

      if age_min.present? || age_max.present?
        # Определение минимального и максимального возрастов
        age_min, age_max = define_ages(event[3], age_min, age_max)

        # Защита от дураков которые указывают отрицателны возраст или больше 20
        age_min, age_max = dammy_protection(age_min, age_max)

        # Приводим возраст к целочисленным индексам. Так как возраст кратен 0.25, умножаем его на 4, чтобы получить
        # целый индекс для будущих массивов
        age_min = (age_min * 4).to_i
        age_max = (age_max * 4).to_i

        # Расчетная числовая оценка
        score = event[2] * calculate_score_for_event(event[0])

        # Формируем векторы оценок по возрастам
        (age_min..age_max).map do |x|
          if genders_raw_data[gender].key?(x)
            genders_raw_data[gender][x] += score
          else
            genders_raw_data[gender][x] = score
          end
        end

      end
    end

    # todo birthdays не отправляются в кликхаус

    # Для каждого пола убираем низкоприоритетные возрасты, оставляя отрезки
    genders_raw_data.keys.each do |_gender|
      if genders_raw_data[_gender].any?
        genders_raw_data[_gender] = genders_raw_data[_gender].sort
        median = genders_raw_data[_gender].map { |x| x[1] }.sum / genders_raw_data[_gender].count.to_f
        genders_raw_data[_gender] = genders_raw_data[_gender].map { |x| x[1] > median ? x : nil }

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
            kid[:age] = (element.first[0].to_f / 4.0)..(element.first[0].to_f / 4.0)
          else
            kid[:age] = (element.sort.first[0] / 4.0)..(element.sort.reverse.first[0].to_f / 4.0)
          end
        end
        kids << kid
      end
    end

    kids

  end

  protected

  # Делает расчеты для отрасли по параметру
  # На выходе что-то вроде: ['BMW', 'Audi']
  # @param [String] industry
  # @param [String] property
  # @param [Number|Array] session_id
  # @return [Hash]
  def calculate_by_property(industry, property, session_id)
    score = {}

    events = ProfileEventCl.where(industry: industry, session_id: session_id, event: %w(view cart purchase), property: property).group(:event, :value).pluck('event, value, count(*)')
    events.each do |event|
      value = event[1]
      score[value] = 0 unless score.key?(value)
      score[value] += event[2] * calculate_score_for_event(event[0])
    end
    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # На выходе массив
    median = score.map { |k, v| v }.max / 2.0
    selected = score.select { |k,v| v >= median }.map { |k,v| k }.sort

    selected.empty? ? nil : selected
  end

  # Делает расчеты для отрасли по параметру
  # На выходе что-то вроде: {'brand' => ['BMW', 'Audi'], 'model' => ['300', 'Aveo']}
  # @param [String] industry
  # @param [String] property
  # @param [Number|Array] session_id
  # @return [Hash]
  def calculate_property_like(industry, property, session_id)
    properties = {}
    score = {}

    # Заполняем хеш сырыми данными
    # Новый метод расчета из кликхауса
    events = ProfileEventCl.where(industry: industry, session_id: session_id, event: %w(view cart purchase)).where("property LIKE '#{property}_%'").group(:event, :value, :property).pluck('event, value, count(*), property')
    events.each do |event|
      key = event[3].gsub("#{property}_", '')
      value = event[1]
      score[key] = {} unless score.key?(key)
      score[key][value] = 0 unless score[key].key?(value)
      score[key][value] += event[2] * calculate_score_for_event(event[0])
    end
    return nil if score.empty?

    # Очищаем маловероятные значения: исключаем те, которые встречаются с частотой в два раза меньше максимальной
    # На выходе что-то вроде: {'brand' => ['BMW', 'Audi'], 'model' => ['300', 'Aveo']}
    score.each do |key, values|
      median = values.map { |k, v| v }.max / 2.0
      selected = values.select { |k,v| v >= median }.map { |k,v| k }.sort
      properties[key] = selected unless selected.empty?
    end

    properties.empty? ? nil : properties
  end

  # Возвращает коэфициент для события
  def calculate_score_for_event(event)
    case event
      when 'cart'
        2
      when 'purchase'
        5
      else
        1
    end
  end

  # Проверка мин / мак возрастов. Учет даты создания события - старение ребенка.
  # @param [Date] event_created_at
  # @param [Number] age_min
  # @param [Number] age_max
  def define_ages(event_created_at, age_min, age_max)
    age_min = age_min.to_f if age_min.present?
    age_max = age_max.to_f if age_max.present?

    # Если не указана одна из границ, определяем ее как вдвое больше/меньше от присутствующей
    age_min = age_max / 2.0 unless age_min.present?
    age_max = age_min * 2.0 unless age_max.present?

    # Сколько месяцев назад было создано событие
    date = Date.current
    difference = (date.year * 12 + date.month) - (event_created_at.year * 12 + event_created_at.month)

    # К возрасту добавляем рассчитаную разницу если она есть
    if difference > 0
      add = difference.to_f / 12
      age_min += add
      age_max += add
    end

    [age_min, age_max]
  end

  # Костыль: У MyToys бывает максимальный возраст в 178956970, поэтому делаем дополнительную проверку
  # И бывают еще отрицательные возрасты.
  def dammy_protection(age_min, age_max)
    age_min = 0 unless (0..20).include?(age_min)

    age_max = 0 if age_max < 0
    age_max = 16 if age_max > 20

    [age_min, age_max]
  end

end
