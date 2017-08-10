class Array
  def normalize!
    xMin,xMax = self.minmax
    dx = (xMax-xMin).to_f
    self.map! { |x| dx == 0 ? 1.0 : ((x-xMin) / dx) }
  end
end