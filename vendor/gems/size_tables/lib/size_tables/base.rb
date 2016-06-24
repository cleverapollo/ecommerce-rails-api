module SizeTables
  class Base
    def table
      {
          m:{
              e:{
                  adult:{},
                  child:{}
              },
              b:{
                  adult:{},
                  child:{}
              },
              u:{
                  adult:{},
                  child:{}
              }
          },

          f:{
              e:{
                  adult:{},
                  child:{}
              },
              b:{
                  adult:{},
                  child:{}
              },
              u:{
                  adult:{},
                  child:{}
              }
          }
      }
    end


    # Определяет числовой размер типа одежды, конвертируя его из размерных сеток разных стран.
    # @param gender [String] Пол: 'm', 'f'
    # @param region [String] Код страны: e (Европа), u (универсальный), b (британский), r (российский)
    # @param key [String] Исходное значение размера: e14, r43, 44, e27
    # @return Integer
    def value(gender, region, age, key)

      # Русские размеры возвращаем как есть
      return key if region == 'r'

      # Невалидные размеры возвращаем как nil
      return nil unless key
      return nil if table[gender.to_sym].nil? || table[gender.to_sym][region.to_sym].nil? || table[gender.to_sym][region.to_sym][age.to_sym].nil?

      value = table[gender.to_sym][region.to_sym][age.to_sym]
      if value
        if value.is_a?(Proc)
          value = value.call(key)
        else
          value = value[key]
        end
      end
      value
    end
  end
end
