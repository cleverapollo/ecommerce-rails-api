module SizeTables
  class Blazer < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size.to_i+6 },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| size.to_i+12 },
                  child: {}
              },
              u: {
                  adult: {
                      'XXS' => 40,
                      'XS' => 44,
                      'S' => 46,
                      'M' => 48,
                      'L' => 50,
                      'XL' => 54,
                      'XXL' => 56,
                      'XXXL' => 60,
                      'XXXXL' => 62,
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
                      'XXS' => 38,
                      'XS' => 40,
                      'S' => 42,
                      'M' => 44,
                      'L' => 46,
                      'XL' => 48,
                      'XXL' => 50,
                      'XXXL' => 52,
                      'XXXXL' => 60,
                  },
                  child: {}
              }
          }
      }
    end
  end
end
