module SizeTables
  class Shoe < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size.to_i-1 },
                  child: {}
              },
              b: {
                  adult: Proc.new do |size|
                    size = size.to_f
                    british_value(size)
                  end,
                  child: {}
              },
              u: {
                  adult: Proc.new {|size| size.to_i+32},
                  child: {}
              }
          },

          f: {
              e: {
                  adult: Proc.new { |size| size.to_i-1 },
                  child: {}
              },
              b: {
                  adult: Proc.new do |size|
                    size = size.to_f
                    british_value(size)
                  end,
                  child: {}
              },
              u: {
                  adult: Proc.new {|size| size.to_i+30},
                  child: {}
              }
          }
      }
    end

    def british_value(size)
      value=nil
      case size
        when 3..5
          value = (size+32).to_i
        when 5.5..6.5
          value = (size+32.5).to_i
        when 7..9
          value = (size+33).to_i
        when 9.5..10.5
          value = (size+33.5).to_i
        when 11..13
          value = (size+34).to_i
        when 13.5
          value = (size+34.5).to_i
        when 14..15
          value = (size+35).to_i
      end
      value
    end
  end
end
