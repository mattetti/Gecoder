require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/constraint_helper'

class ArithmeticSampleProblem < Gecode::Model
  attr :numbers
  attr :var
  attr :var2
  
  def initialize
    @numbers = int_var_array(4, 0..9)
    @var = int_var(-9..9)
    @var2 = int_var(0..9)
    branch_on @numbers
    branch_on wrap_enum([@var, @var2])
  end
end

describe Gecode::Constraints::IntEnum::Arithmetic, ' (max)' do
  before do
    @model = ArithmeticSampleProblem.new
    @numbers = @model.numbers
    @target = @var = @model.var
    @stub = @numbers.max
    
    # Creates an expectation corresponding to the specified input.
    @expect = lambda do |relation, rhs, strength, reif_var, negated|
      rhs = rhs.bind if rhs.respond_to? :bind
      if reif_var.nil?
        if !negated and relation == Gecode::Raw::IRT_EQ and 
            rhs.kind_of? Gecode::Raw::IntVar 
          Gecode::Raw.should_receive(:max).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVarArray), rhs, strength)
        else
          Gecode::Raw.should_receive(:max).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVarArray), 
            an_instance_of(Gecode::Raw::IntVar), strength)
          Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVar), relation, rhs, strength)
        end
      else
        Gecode::Raw.should_receive(:max).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVarArray), 
          an_instance_of(Gecode::Raw::IntVar), strength)
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, reif_var.bind,
          strength)
      end
    end
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      @numbers.max.must_be.greater_than(@var, hash) 
      @model.solve!
    end
    @expect_options = lambda do |strength, reif_var|
      @expect.call(Gecode::Raw::IRT_GR, @var, strength, reif_var, false)
    end
    
    # For composite spec.
    @invoke_relation = lambda do |relation, target, negated|
      if negated
        @numbers.max.must_not.send(relation, target)
      else
        @numbers.max.must.send(relation, target)
      end
      @model.solve!
    end
    @expect_relation = lambda do |relation, target, negated|
      @expect.call(relation, target, Gecode::Raw::ICL_DEF, nil, negated)
    end
  end
  
  it 'should constrain the maximum value' do
    @numbers.max.must > 5
    @model.solve!.numbers.map{ |n| n.val }.max.should > 5
  end
  
  it 'should translate reification when using equality' do
    bool_var = @model.bool_var
    @expect.call(Gecode::Raw::IRT_EQ, @target, Gecode::Raw::ICL_DEF, bool_var, 
      false)
    @numbers.max.must_be.equal_to(@target, :reify => bool_var)
    @model.solve!
  end
  
  it_should_behave_like 'composite constraint'
  it_should_behave_like 'constraint with options'
end

describe Gecode::Constraints::IntEnum::Arithmetic, ' (min)' do
  before do
    @model = ArithmeticSampleProblem.new
    @numbers = @model.numbers
    @target = @var = @model.var
    @stub = @numbers.min
    
    # Creates an expectation corresponding to the specified input.
    @expect = lambda do |relation, rhs, strength, reif_var, negated|
      rhs = rhs.bind if rhs.respond_to? :bind
      if reif_var.nil?
        if !negated and relation == Gecode::Raw::IRT_EQ and 
            rhs.kind_of? Gecode::Raw::IntVar 
          Gecode::Raw.should_receive(:min).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVarArray), rhs, strength)
        else
          Gecode::Raw.should_receive(:min).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVarArray), 
            an_instance_of(Gecode::Raw::IntVar), strength)
          Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
            an_instance_of(Gecode::Raw::IntVar), relation, rhs, strength)
        end
      else
        Gecode::Raw.should_receive(:min).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVarArray), 
          an_instance_of(Gecode::Raw::IntVar), an_instance_of(Fixnum))
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, reif_var.bind,
          strength)
      end
    end
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      @numbers.min.must_be.greater_than(@var, hash) 
      @model.solve!
    end
    @expect_options = lambda do |strength, reif_var|
      @expect.call(Gecode::Raw::IRT_GR, @var, strength, reif_var, false)
    end
    
    # For composite spec.
    @invoke_relation = lambda do |relation, target, negated|
      if negated
        @numbers.min.must_not.send(relation, target)
      else
        @numbers.min.must.send(relation, target)
      end
      @model.solve!
    end
    @expect_relation = lambda do |relation, target, negated|
      @expect.call(relation, target, Gecode::Raw::ICL_DEF, nil, negated)
    end
  end
  
  it 'should constrain the minimum value' do
    @numbers.min.must > 5
    @model.solve!.numbers.map{ |n| n.val }.min.should > 5
  end
  
  it 'should translate reification when using equality' do
    bool_var = @model.bool_var
    @expect.call(Gecode::Raw::IRT_EQ, @target, Gecode::Raw::ICL_DEF, bool_var, 
      false)
    @numbers.min.must_be.equal_to(@target, :reify => bool_var)
    @model.solve!
  end
  
  it_should_behave_like 'composite constraint'
  it_should_behave_like 'constraint with options'
end

describe 'single variable arithmetic constraint', :shared => true do
  situations = {
    'variable bound' => nil,
    'constant bound' => 5
  }.each_pair do |description, bound|
    Gecode::Constraints::Util::RELATION_TYPES.each_pair do |relation, type|
      it "should translate #{relation} with #{description}" do
        bound = @var if bound.nil?
        @expect.call(type, bound, Gecode::Raw::ICL_DEF, nil)
        @stub.must.send(relation, bound)
        @model.solve!
      end
    end
    Gecode::Constraints::Util::NEGATED_RELATION_TYPES.each_pair do |relation, type|
      it "should translate negated #{relation} with #{description}" do
        bound = @var if bound.nil?
        @expect.call(type, bound, Gecode::Raw::ICL_DEF, nil)
        @stub.must_not.send(relation, bound)
        @model.solve!
      end
    end
  end
  
  it 'should raise error if the right hand side is of the wrong type' do
    lambda{ @stub.must == 'hello' }.should raise_error(TypeError) 
  end
end

describe Gecode::Constraints::Int::Arithmetic, ' (abs)' do
  before do
    @model = ArithmeticSampleProblem.new
    @var = @model.var
    @stub = @var.abs
    
    # Creates an expectation corresponding to the specified input.
    @expect = lambda do |relation, rhs, strength, reif_var|
      rhs = rhs.bind if rhs.respond_to? :bind
      if reif_var.nil?
        Gecode::Raw.should_receive(:abs).once.with(@model.active_space,
          @var.bind, an_instance_of(Gecode::Raw::IntVar), 
          an_instance_of(Fixnum))
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, strength)
      else
        Gecode::Raw.should_receive(:abs).once.with(@model.active_space,
          @var.bind, an_instance_of(Gecode::Raw::IntVar), 
          an_instance_of(Fixnum))
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, reif_var.bind,
          strength)
      end
    end
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      @var.abs.must_be.greater_than(@var, hash) 
      @model.solve!
    end
    @expect_options = lambda do |strength, reif_var|
      @expect.call(Gecode::Raw::IRT_GR, @var, strength, reif_var)
    end
  end
  
  it 'should constrain the absolute value' do
    @var.must < 0
    @var.abs.must == 5
    @model.solve!.var.val.should == -5
  end
  
  it_should_behave_like 'single variable arithmetic constraint'
  it_should_behave_like 'constraint with options'
end

describe Gecode::Constraints::Int::Arithmetic, ' (multiplication)' do
  before do
    @model = ArithmeticSampleProblem.new
    @var = @model.var
    @var2 = @model.var2
    @stub = @var * @var2
    
    # Creates an expectation corresponding to the specified input.
    @expect = lambda do |relation, rhs, strength, reif_var|
      rhs = rhs.bind if rhs.respond_to? :bind
      if reif_var.nil?
        Gecode::Raw.should_receive(:mult).once.with(@model.active_space,
          @var.bind, @var2.bind, an_instance_of(Gecode::Raw::IntVar), 
          an_instance_of(Fixnum))
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, strength)
      else
        Gecode::Raw.should_receive(:mult).once.with(@model.active_space,
          @var.bind, @var2.bind, an_instance_of(Gecode::Raw::IntVar), 
          an_instance_of(Fixnum))
        Gecode::Raw.should_receive(:rel).once.with(@model.active_space, 
          an_instance_of(Gecode::Raw::IntVar), relation, rhs, reif_var.bind,
          strength)
      end
    end
    
    # For constraint option spec.
    @invoke_options = lambda do |hash| 
      (@var * @var2).must_be.greater_than(@var, hash) 
      @model.solve!
    end
    @expect_options = lambda do |strength, reif_var|
      @expect.call(Gecode::Raw::IRT_GR, @var, strength, reif_var)
    end
  end
  
  it 'should constrain the value of the multiplication' do
    (@var * @var2).must == 56
    sol = @model.solve!
    [sol.var.val, sol.var2.val].sort.should == [7, 8]
  end
  
  it 'should not interfere with other defined multiplication methods' do
    (@var * :foo).should be_nil
  end
  
  it_should_behave_like 'single variable arithmetic constraint'
  it_should_behave_like 'constraint with options'
end