module UserProfile
  # @deprecated
  module ChildrenCalculator
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

          # Определение минимального и максимального возрастов
          age_min, age_max = define_ages(event.created_at, age_min, age_max)

          # Защита от дураков которые указывают отрицателны возраст или больше 20
          age_min, age_max = dammy_protection(age_min, age_max)

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
        end
      end

      birthdays = []

      ProfileEvent.where(user_id: user.id, industry: 'child', property: 'push_attributes_children').each do |event|
        birthday = /(\d+.-\d+.\d+.)/.match(event.value).to_a[0]
        gender = /gender:(.);/.match(event.value).to_a[1] || 'u'


        if birthday.present?
          birthday_date = Date.parse(birthday, '%Y-%m-%d')
          difference = (Date.current - birthday_date).to_i / 30

          age = (difference > 24 ? difference / 12 : ((difference - 1) / 3 + 1) * 0.25) * 4

          score = 20

          if genders_raw_data[gender].key?(age)
            genders_raw_data[gender][age] += score
          else
            genders_raw_data[gender][age] = score
          end

          birthdays << { birthday: birthday, gender: gender, age: age/4 }
        end
      end

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

      kids.each do |kid|
        birthdays.select{|arr| arr[:gender] == kid[:gender]}.each do |birthday|
          kid[:birthday] = birthday[:birthday] if (kid[:age_min]..kid[:age_max]).include?(birthday[:age])
        end
      end

      kids

    end

    private

    def define_ages(event_created_at, age_min, age_max)
      age_min = age_min.to_f if age_min.present?
      age_max = age_max.to_f if age_max.present?

      # Если не указана одна из границ, определяем ее как вдвое больше/меньше от присутствующей
      age_min = age_max / 2.0 unless age_min.present?
      age_max = age_min * 2.0 unless age_max.present?

      # Сколько месяцев назад было создано событие
      difference = (Date.current - event_created_at.to_date).to_i / 30

      # К возрасту добавляем рассчитаную разницу если она есть
      if difference > 0
        # рассчитано согласно таблици в доке
        # http://docs.rees46.com/pages/viewpage.action?pageId=3736045#id-Детскиетовары-Возраст(<age>)
        add = difference > 24 ? difference / 12 : ((difference - 1) / 3 + 1) * 0.25
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

    def put_age_vector_in_raw_data(raw_data, gender, age_min, age_max)

    end

  end
end
