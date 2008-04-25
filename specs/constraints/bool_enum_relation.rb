require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/constraint_helper'

class BoolEnumSampleProblem < Gecode::Model
  attr :bools
  attr :b1
  attr :b2
  
  def initialize
    @bools = bool_var_array(4)
    @b1 = bool_var
    @b2 = bool_var
    branch_on @bools
    branch_on wrap_enum([@b1, @b2])
  end
end

# Expects @stub, which contains the started constraint and @compute_result which 
# computes whether the left hand side is true or not.
describe 'bool enum relation constraint', :shared => true do
  it 'should handle being constrained to be true' do
    @stub.must_be.true
    @model.solve!
    @compute_result.call.should be_true
  end
  
  it 'should handle being constrained to be negated true' do
    @stub.must_not_be.true
    @model.solve!
    @compute_result.call.should_not be_true
  end
  
  it 'should handle being constrained to be false' do
    @stub.must_be.false
    @model.solve!
    @compute_result.call.should_not be_true
  end
  
  it 'should handle being constrained to be negated false' do
    @stub.must_not_be.false
    @model.solve!
    @compute_result.call.should be_true
  end
  
  it 'should handle being constrained to be equal to a variable' do
    @stub.must_be == @b1
    @model.solve!
    @compute_result.call.should == @b1.value
  end
  
  it 'should handle being constrained to not be equal to a variable' do
    @stub.must_not_be == @b1
    @model.solve!
    @compute_result.call.should_not == @b1.value
  end
  
  it 'should handle being constrained to be equal to be a nested expression' do
    @stub.must_be == (@b1 | @b2) & @b1
    @model.solve!
    @compute_result.call.should == (@b1.value | @b2.value) & @b1.value
  end
  
  it 'should handle being constrained to not be equal to be a nested expression' do
    @stub.must_not_be == (@b1 | @b2) & @b1
    @model.solve!
    @compute_result.call.should_not == (@b1.value | @b2.value) & @b1.value
  end
end

describe Gecode::Constraints::BoolEnum::Relation, ' (conjunction)' do
  before do
    @model = BoolEnumSampleProblem.new
    @bools = @model.bools
    @b1 = @model.b1
    @b2 = @model.b2
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      @bools.conjunction.must_be.equal_to(true, hash) 
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      @model.allow_space_access do
        if reif_var.nil?
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space),
            Gecode::Raw::BOT_AND, 
            an_instance_of(Gecode::Raw::BoolVarArray),
            an_instance_of(Gecode::Raw::BoolVar), 
            strength, kind)
        else
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::BoolVar),
            anything,
            an_instance_of(Gecode::Raw::BoolVar),
            anything, anything, anything)
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space), 
            Gecode::Raw::BOT_AND, 
            an_instance_of(Gecode::Raw::BoolVarArray),
            reif_var, strength, kind)
        end
      end
    end
    
    # For bool enum spec.
    @stub = @bools.conjunction
    @compute_result = lambda{ @bools.all?{ |b| b.value } }
  end
  
  it_should_behave_like 'bool enum relation constraint'
  it_should_behave_like 'reifiable constraint'
end

describe Gecode::Constraints::BoolEnum::Relation, ' (disjunction)' do
  before do
    @model = BoolEnumSampleProblem.new
    @bools = @model.bools
    @b1 = @model.b1
    @b2 = @model.b2
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      @bools.disjunction.must_be.equal_to(true, hash) 
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      @model.allow_space_access do
        if reif_var.nil?
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space), 
            Gecode::Raw::BOT_OR, 
            an_instance_of(Gecode::Raw::BoolVarArray),
            an_instance_of(Gecode::Raw::BoolVar), 
            strength, kind)
        else
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::BoolVar),
            anything,
            an_instance_of(Gecode::Raw::BoolVar),
            anything, anything, anything)          
          Gecode::Raw.should_receive(:rel).once.with(
            an_instance_of(Gecode::Raw::Space), 
            Gecode::Raw::BOT_OR, 
            an_instance_of(Gecode::Raw::BoolVarArray),
            reif_var, strength, kind)
        end
      end
    end
    
    # For bool enum spec.
    @stub = @bools.disjunction
    @compute_result = lambda{ @bools.any?{ |b| b.value } }
  end
  
  it_should_behave_like 'bool enum relation constraint'
  it_should_behave_like 'reifiable constraint'
end