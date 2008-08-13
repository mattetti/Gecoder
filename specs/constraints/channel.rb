require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/constraint_helper'

class ChannelSampleProblem < Gecode::Model
  attr :elements
  attr :positions
  attr :sets
  
  def initialize
    @elements = int_var_array(4, 0..3)
    @elements.must_be.distinct
    @positions = int_var_array(4, 0..3)
    @positions.must_be.distinct
    @sets = set_var_array(4, [], 0..3)
    branch_on @positions
  end
end

class BoolChannelSampleProblem < Gecode::Model
  attr :bool_enum
  attr :bool
  attr :int
  
  def initialize
    @bool_enum = bool_var_array(4)
    @int = int_var(0..3)
    @bool = bool_var
    
    branch_on @int
  end
end

class SetChannelSampleProblem < Gecode::Model
  attr :bool_enum
  attr :set
  
  def initialize
    @bool_enum = bool_var_array(4)
    @set = set_var([], 0..3)
    
    branch_on @bool_enum
  end
end

describe Gecode::Constraints::SetEnum::Channel::IntChannelConstraint, ' (channel with set as right hand side)' do
  before do
    @model = ChannelSampleProblem.new
    @positions = @model.positions
    @sets = @model.sets
    
    @invoke_options = lambda do |hash| 
      @positions.must.channel @sets, hash
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      Gecode::Raw.should_receive(:channel).once.with(
        an_instance_of(Gecode::Raw::Space), 
        an_instance_of(Gecode::Raw::IntVarArray), 
        an_instance_of(Gecode::Raw::SetVarArray))
    end
  end

  it 'should translate into a channel constraint' do
    @expect_options.call({})
    @positions.must.channel @sets
    @model.solve!
  end
  
  it 'should constrain variables to be channelled' do
    @positions.must.channel @sets
    @model.solve!
    sets = @model.sets
    positions = @model.positions.values
    positions.each_with_index do |position, i|
      sets[position].value.should include(i)
    end
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end

describe Gecode::Constraints::SetEnum::Channel::IntChannelConstraint, ' (channel with set as left hand side)' do
  before do
    @model = ChannelSampleProblem.new
    @positions = @model.positions
    @sets = @model.sets
    
    @invoke_options = lambda do |hash| 
      @sets.must.channel @positions, hash
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      Gecode::Raw.should_receive(:channel).once.with(
        an_instance_of(Gecode::Raw::Space), 
        an_instance_of(Gecode::Raw::IntVarArray), 
        an_instance_of(Gecode::Raw::SetVarArray))
    end
  end

  it 'should translate into a channel constraint' do
    @expect_options.call({})
    @sets.must.channel @positions
    @model.solve!
  end

  it 'should not allow negation' do
    lambda{ @sets.must_not.channel @positions }.should raise_error(
      Gecode::MissingConstraintError) 
  end
  
  it 'should raise error for unsupported right hand sides' do
    lambda{ @sets.must.channel 'hello' }.should raise_error(TypeError) 
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end

# Requires @model, @bool_enum and @set. Also requires @place_constraint which 
# is a method that takes four variables: a boolean enum, a set variable,
# whether or not the constraint should be negated and a hash of options, and 
# places the channel constraint on them.
describe 'channel constraint between set variable and bool enum', :shared => true do
  before do
    @invoke_options = lambda do |hash| 
      @place_constraint.call(@bools, @set, false, hash)
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      Gecode::Raw.should_receive(:channel).once.with(
        an_instance_of(Gecode::Raw::Space), 
        an_instance_of(Gecode::Raw::BoolVarArray),
        an_instance_of(Gecode::Raw::SetVar))
    end
  end
  
  it 'should channel the bool enum with the set variable' do
    @set.must_be.superset_of [0, 2]
    @place_constraint.call(@bools, @set, false, {})
    @model.solve!.should_not be_nil
    set_values = @set.value
    @bools.values.each_with_index do |bool, index|
      bool.should == set_values.include?(index)
    end
  end
  
  it 'should not allow negation' do
    lambda do
      @place_constraint.call(@bools, @set, true, {})
    end.should raise_error(Gecode::MissingConstraintError) 
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end

describe Gecode::Constraints::Set::Channel, ' (set variable as lhs with bool enum)' do
  before do
    @model = SetChannelSampleProblem.new
    @bools = @model.bool_enum
    @set = @model.set
    
    @place_constraint = lambda do |bools, set, negate, options|
      unless negate
        set.must.channel(bools, options)
      else
        set.must_not.channel(bools, options)
      end
    end
  end

  it 'should raise error if a boolean enum is not given as right hand side' do
    lambda do
      @set.must.channel 'hello'
    end.should raise_error(TypeError) 
  end
  
  it_should_behave_like 'channel constraint between set variable and bool enum'
end

describe Gecode::Constraints::Set::Channel, ' (bool enum as lhs with set variable)' do
  before do
    @model = SetChannelSampleProblem.new
    @bools = @model.bool_enum
    @set = @model.set
    
    @place_constraint = lambda do |bools, set, negate, options|
      unless negate
        bools.must.channel(set, options)
      else
        bools.must_not.channel(set, options)
      end
    end
  end

  it 'should raise error if an integer variable is not given as right hand side' do
    lambda do
      @bools.must.channel 'hello'
    end.should raise_error(TypeError) 
  end
  
  it_should_behave_like 'channel constraint between set variable and bool enum'
end
