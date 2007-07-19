require File.dirname(__FILE__) + '/example_helper'

# Computes the maximum slice of an array. This is not something you want to use
# constraint programming for as good algorithms are known. This is just to show 
# how it can be done.
class MaxSlice < Gecode::Model
  attr :substitutions
  attr :indices
  attr :start
  attr :length
  
  def initialize(array)
    @array = array
    @start, @length = int_var_array(2, 0..array.size)
    (@start + @length).must <= array.size
    
    # Sumation substitutions.
    @substitutions = Hash[*(0...array.size).zip(array).flatten]

    # Set up a set of indices, we constrain it to be a range starting at @start
    # with length @length.
    @indices = set_var([], 0...array.size)
    @indices.min.must == @start
    @indices.max.must == @start + @length - 1
    @indices.size.must == @length

    # Implied constraints.
    #@indices.sum(:substitutions => @substitutions).must >= 0
    
    branch_on wrap_enum([@start, @length])
  end
  
  def sum
    @substitutions.values_at(*@indices.value.to_a).inject(0){ |x,y| x + y }
  end
  
  def value
    @array.slice(@start.value, @length.value)
  end
end

array = Array.new(4) { rand(11) - 5 }
p array
solution = MaxSlice.new(array).optimize! do |model, best_so_far|
  model.indices.sum(:substitutions => model.substitutions).must > best_so_far.sum
end
p solution.value

