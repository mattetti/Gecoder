require File.dirname(__FILE__) + '/example_helper'

# Computes the maximum slice of an array. This is not something you want to use
# constraint programming for as good algorithms are known. This is just to show 
# how it can be done.
class MaxSlice < Gecode::Model
  attr :substitutions
  attr :indices
  
  def initialize(array)
    @array = array
    start, stop = int_var_array(2, 0...array.size)
    start.must <= stop
    
    # Sumation substitutions.
    @substitutions = Hash[*(0...array.size).zip(array).flatten]
    
    # Set up a set of indices.
    @indices = set_var([], 0...array.size)
    @indices.min.must == start
    @indices.max.must == stop

    # Implied constraints.
    #@indices.sum(:substitute => @substitutions).must >= 0
    
    branch_on wrap_enum([start, stop])
  end
  
  def sum
    @substitutions.values_at(*@indices.value.to_a).inject(0){ |x,y| x + y }
  end
  
  def value
    @array.slice(start.value, stop.value)
  end
end

array = [2,4,-5,2]
solution = MaxSlice.new(array).optimize! do |model, best_so_far|
  model.indices.sum(:substitutes => model.substitutions).must > best_so_far.sum
end
puts solution.value
