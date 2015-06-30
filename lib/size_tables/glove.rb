module SizeTables
  class Glove < Base
    def table
      {
          m: {
              e: {
                  adult: Proc.new { |size| size },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| (size * 2.5).to_i },
                  child: {}
              },
              u: {
                  adult: {
                      'XS' => 19,
                      'S' => 20,
                      'M' => 21,
                      'L' => 23,
                      'XL' => 24,
                      'XXL' => 25,
                      'XXXL' => 26,
                      'XXXXL' => 27,
                  },
                  child: {}
              }
          },

          f: {
              e: {
                  adult: Proc.new { |size| size },
                  child: {}
              },
              b: {
                  adult: Proc.new { |size| (size * 2.5).to_i },
                  child: {}
              },
              u: {
                  adult: {
                      'XS' => 15,
                      'S' => 16,
                      'M' => 17,
                      'L' => 19,
                      'XL' => 20
                  },
                  child: {}
              }
          }
      }
    end
  end
end
