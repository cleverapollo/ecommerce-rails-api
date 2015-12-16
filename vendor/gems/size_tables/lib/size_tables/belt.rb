module SizeTables
  class Belt < Base
    def table
      {
          m: belt_sizes,

          f: belt_sizes
      }
    end

    def belt_sizes
      {
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
                  'XXS' => 60,
                  'XS' => 70,
                  'S' => 80,
                  'M' => 90,
                  'L' => 100,
                  'XL' => 105,
                  'XXL' => 110,
                  'XXXL' => 115,
              },
              child: {}
          }
      }
    end
  end
end
