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

    def value(gender, region, age, key)

      return nil unless key

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
