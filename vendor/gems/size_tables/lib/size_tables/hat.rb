module SizeTables
  class Hat < Base
    def table
      {
          m: hat_sizes,

          f: hat_sizes
      }
    end

    def hat_sizes
      {
          e: {
              adult: Proc.new { |size| size.to_i },
              child: {}
          },
          b: {
              adult: {
                  '6 3/4' => 54,
                  '6 7/8' => 55,
                  '7' => 56,
                  '7 1/8' => 57,
                  '7 1/4' => 58,
                  '7 3/8' => 59,
                  '7 1/2' => 60,
                  '7 5/8' => 61,
                  '7 3/4' => 62,
                  '7 7/8' => 63,
                  '8' => 64,
                  '8 1/8' => 65,
              },
              child: {}
          },
          u: {
              adult: {
                  'XXS' => 54,
                  'XS' => 55,
                  'S' => 56,
                  'M' => 57,
                  'L' => 58,
                  'XL' => 59,
                  'XXL' => 60,
                  'XXXL' => 62,
                  'XXXXL' => 64,
              },
              child: {}
          }
      }
    end
  end
end
