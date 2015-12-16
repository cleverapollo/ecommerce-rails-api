module SizeTables
  class Tshirt < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size.to_i+2 },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| size.to_i+34 },
                  child: {}
              },
              u: {
                  adult: {
                      'XXS' => 42,
                      'XS' => 44,
                      'S' => 46,
                      'M' => 48,
                      'L' => 50,
                      'XL' => 54,
                      'XXL' => 56,
                      'XXXL' => 58
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
                  adult: Proc.new { |size| size.to_i+34 },
                  child: {}
              },
              u: {
                  adult: {
                      'XXS' => 40,
                      'XS' => 42,
                      'S' => 44,
                      'M' => 46,
                      'L' => 48,
                      'XL' => 50,
                      'XXL' => 52,
                      'XXXL' => 54
                  },
                  child: {}
              }
          }
      }
    end
  end
end
