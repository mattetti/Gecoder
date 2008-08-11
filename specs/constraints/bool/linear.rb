require File.dirname(__FILE__) + '/../constraint_helper'

class BoolLinearSampleProblem < Gecode::Model
  attr :x
  attr :y
  attr :z
  
  def initialize
    @x = self.bool_var
    @y = self.bool_var
    @z = self.bool_var
    branch_on wrap_enum([@x, @y, @z])
  end
end

class TrueClass
  def to_i
    1
  end
end

class FalseClass
  def to_i
    0
  end
end

describe Gecode::Constraints::Int::Linear, '(with booleans)' do
  before do
    @model = BoolLinearSampleProblem.new
    @x = @model.x
    @y = @model.y
    @z = @model.z
    @operand = @x + @y
  end

  it 'should handle addition with a variable' do
    (@x + @y).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    (x + y).should be_zero
  end
  
  it 'should handle addition with multiple variables' do
    (@x + @y + @z).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    z = sol.z.value.to_i
    (x + y + z).should be_zero
  end
  
  it 'should handle subtraction with a variable' do
    (@x - @y).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    (x - y).should be_zero
  end
  
  it 'should handle non-zero constants as right hand side' do
    (@x + @y).must == 1
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    (x + y).should equal(1)
  end
  
  it 'should handle single booleans as left hand side' do
    @x.must == @y + 1 
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    x.should equal(y + 1)
  end
  
  it 'should handle variables as right hand side' do
    (@x + @y).must == @z
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    z = sol.z.value.to_i
    (x + y).should equal(z)
  end
  
  it 'should handle linear expressions as right hand side' do
    (@x + @y).must == @z + @y
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    z = sol.z.value.to_i
    (x + y).should equal(z + y)
  end
  
  it 'should raise error on invalid right hand sides' do
    lambda{ ((@x + @y).must == 'z') }.should raise_error(TypeError) 
  end
  
  it 'should handle coefficients other than 1' do
    (@x * 2 + @y).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    (2*x + y).should equal(0)
  end
  
  it 'should handle addition with constants' do
    (@y + 1).must == 1
    sol = @model.solve!
    y = sol.y.value.to_i
    (y + 1).should equal(1)
  end
  
  it 'should handle subtraction with a constant' do
    (@x - 1).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    (x - 1).should be_zero
  end

  it 'should handle parenthesis' do
    (@x - (@y + @z)).must == 1
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    z = sol.z.value.to_i
    (x - (y + z)).should equal(1)
  end
  
  it 'should handle multiplication of parenthesis' do
    (((@x + @y*10)*10 + @z)*10).must == 0
    sol = @model.solve!
    x = sol.x.value.to_i
    y = sol.y.value.to_i
    z = sol.z.value.to_i
    (((x + y*10)*10 + z)*10).should equal(0)
  end
  
  relations = ['>', '>=', '<', '<=', '==']
  
  relations.each do |relation|
    it "should handle #{relation} with constant integers" do
      (@x + @y).must.send(relation, 1)
      sol = @model.solve!
      sol.should_not be_nil
      (sol.x.value.to_i + sol.y.value.to_i).should.send(relation, 1)
    end
  end
  
  relations.each do |relation|
    it "should handle negated #{relation} with constant integers" do
      (@x + @y).must_not.send(relation, 1)
      sol = @model.solve!
      sol.should_not be_nil
      (sol.x.value.to_i + sol.y.value.to_i).should_not.send(relation, 1)
    end
  end
  
  it 'should not interfere with other defined multiplication methods' do
    (@x * :foo).should be_nil
  end
end


