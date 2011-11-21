#  Add methods to Enumerable, which makes them available to Array
module Enumerable

  #  sum of an array of numbers
  def sum
    return self.inject(0){ |acc,i| acc + i }
  end

  #  average of an array of numbers
  def mean
    return self.sum/self.length.to_f
  end

  #  variance of an array of numbers
  def variance
    avg=self.mean
    sum=self.inject(0){ |acc,i| acc + (i-avg)**2 }
    sum / self.length.to_f
  end

  #  standard deviation of an array of numbers
  def stdDev
    return Math.sqrt(self.variance)
  end

  def fiveNumSum
      data = self.sort
      min = data[0].to_f
      max = data[-1].to_f
      med = self.median
      low_half = nil
      hi_half = nil
      if (data.size % 2 == 0) then #even
        low_half = data[0..(data.size/2-1)]
        hi_half =  data[(data.size/2)..(data.size-1)]
      else #odd
        low_half = data[0..(data.size/2-1)]
        hi_half =  data[(data.size/2+1)..(data.size-1)]
      end
      q1  = low_half.median
      q3  = hi_half.median
      Array.[](min,q1,med,q3,max)
  end # fiveNumSum

  # Return the median of a set of data
  #
  # ==== Parameters
  #
  # [+:data_in+] An array of data to be analyzed
  #

  def median
    data = self.sort
    if (data.size % 2 == 0) then #even
      (data[data.size/2-1].to_f + data[data.size/2].to_f)/2
    else #odd
      data[(data.size-1)/2].to_f
    end
  end # median

end  #  module Enumerable
