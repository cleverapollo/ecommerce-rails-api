module SizeTables
  class Sock < Base
    def table
      {
          m: socks_sizes,

          f: socks_sizes
      }
    end

    def socks_sizes
      {
          e: {
              adult: Proc.new { |size| size.to_i - 14 },
              child: Proc.new { |size| size.to_i - 14 },
          },
          b: {
              adult: Proc.new { |size| size.to_i + 15 },
              child: Proc.new { |size| size.to_i + 15 },
          },
          u: {
              adult: {
                  'S' => 23,
                  'M' => 25,
                  'L' => 27,
                  'XL' => 29,
                  'XXL' => 31,
              },
              child: {
                  'S' => 10,
                  'M' => 12,
                  'L' => 14,
                  'XL' => 16,
                  'XXL' => 18,
              }
          }
      }
    end
  end
end
