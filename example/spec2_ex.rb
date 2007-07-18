require File.dirname(__FILE__) + '/example_helper'

class SampleOptimizationProblem2 < Gecode::Model
  attr :money
  
  def initialize
    @money = int_var_array(3, 0..9)
    @money.must_be.distinct
    
    branch_on @money, :variable => :smallest_size, :value => :min
  end
end

class Array
  # Computes a number of the specified base using the array's elements as 
  # digits.
  def to_number(base = 10)
    inject{ |result, variable| variable + result * base }
  end
end

SampleOptimizationProblem2.new.optimize! do |model, best_so_far|
  p best_so_far.money.values.to_number
  model.money.to_number.must > best_so_far.money.values.to_number
end