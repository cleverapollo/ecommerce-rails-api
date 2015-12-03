module SizeTables
  class Shirt < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size },
                  child: {}
              },
              b: {
                  adult: Proc.new do |size|
                    value = (size*2).to_i
                    if value<30
                      value += 8
                    else
                      value += 9
                    end
                    value
                  end,
                  child: {}
              },
              u: {
                  adult: {
                      'XS' => 35,
                      'S' => 37,
                      'M' => 39,
                      'L' => 41,
                      'XL' => 43,
                      'XXL' => 45,
                      'XXXL' => 47,
                  },
                  child: {}
              }
          },

          f: {
              e: {
                  adult: Proc.new { |size| size.to_i+6 },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| size.to_i+32 },
                  child: {}
              },
              u: {
                  adult: {
                      'XS' => 40,
                      'S' => 42,
                      'M' => 46,
                      'L' => 50,
                      'XL' => 52,
                      'XXL' => 54,
                      'XXXL' => 56,
                  },
                  child: {}
              }
          }
      }
    end
  end
end
