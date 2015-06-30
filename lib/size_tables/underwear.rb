module SizeTables
  class Underwear < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size.to_i*2 + 40 },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| size.to_i + 12 },
                  child: {}
              },
              u: {
                  adult: {
                      'XS' => 44,
                      'S' => 46,
                      'M' => 48,
                      'L' => 50,
                      'XL' => 52,
                      'XXL' => 54,
                      'XXXL' => 56,
                  },
                  child: {}
              }
          },

          f: {
              e: {
                  adult: Proc.new { |size| size.to_i + 4 },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| size.to_i + 18 },
                  child: {}
              },
              u: {
                  adult: {
                      'XXS' => 42,
                      'XS' => 44,
                      'S' => 46,
                      'M' => 48,
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
