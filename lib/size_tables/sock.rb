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
              child: {}
          },
          b: {
              adult: Proc.new { |size| size.to_i + 15 },
              child: {}
          },
          u: {
              adult: {
                  'S' => 23,
                  'M' => 25,
                  'L' => 27,
                  'XL' => 29,
                  'XXL' => 31,
              },
              child: {}
          }
      }
    end
  end
end
