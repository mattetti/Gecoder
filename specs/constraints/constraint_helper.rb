require File.dirname(__FILE__) + '/../spec_helper'

# Several of these shared specs requires one or more of the following instance 
# variables to be used: 
# [@expect_options]  A method that creates an expectation on the aspect to be 
#                    tested, using the provided operand variable and hash of 
#                    Gecode values. The hash can have values for the keys :icl 
#                    (ICL_*), :pk (PK_*), and :bool (bound reification 
#                    variable). Any values not provided are assumed to be 
#                    default values (nil in the case of :bool).
# [@invoke_options]  A method that invokes the aspect to be tested, with the 
#                    provided operand and hash of options (with at most the 
#                    keys :strength, :kind and :reify).
# [@operand]         An operand of a type that has the constraint that
#                    is being tested.
# [@model]           The model instance that contains the aspects being tested.
# [@expect_relation] A method that takes a relation, right hand side, and 
#                    whether it's negated, as arguments and sets up the 
#                    corresponding expectations. 
# [@invoke_relation] A method that takes a relation, right hand side, and 
#                    whether it's negated, as arguments and adds the 
#                    corresponding constraint and invokes it.
# [@target]          A legal right hand side that can be used as argument to 
#                    the above two methods.


# Requires @operand, @invoke_options and @expect_options.
describe 'constraint with strength option', :shared => true do
  { :default  => Gecode::Raw::ICL_DEF,
    :value    => Gecode::Raw::ICL_VAL,
    :bounds   => Gecode::Raw::ICL_BND,
    :domain   => Gecode::Raw::ICL_DOM
  }.each_pair do |name, gecode_value|
    it "should translate propagation strength #{name}" do
      @expect_options.call(anything, :icl => gecode_value)
      @invoke_options.call(@operand, :strength => name)
    end
  end
  
  it 'should default to using default as propagation strength' do
    @expect_options.call(anything, {})
    @invoke_options.call(@operand, {})
  end
  
  it 'should raise errors for unrecognized propagation strengths' do
    lambda do 
      @invoke_options.call(@operand, :strength => :does_not_exist) 
    end.should raise_error(ArgumentError)
  end
end

# Requires @operand, @invoke_options and @expect_options.
describe 'constraint with kind option', :shared => true do
  { :default  => Gecode::Raw::PK_DEF,
    :speed    => Gecode::Raw::PK_SPEED,
    :memory   => Gecode::Raw::PK_MEMORY
  }.each_pair do |name, gecode_value|
    it "should translate propagation kind #{name}" do
      @expect_options.call(anything, :pk => gecode_value)
      @invoke_options.call(@operand, :kind => name)
    end
  end
  
  it 'should default to using default as propagation kind' do
    @expect_options.call(anything, {})
    @invoke_options.call(@operand, {})
  end
  
  it 'should raise errors for unrecognized propagation kinds' do
    lambda do 
      @invoke_options.call(@operand, :kind => :does_not_exist)
    end.should raise_error(ArgumentError)
  end
end

# Requires @operand, @invoke_options and @expect_options.
describe 'constraint with reification option', :shared => true do
  it 'should translate reification' do
    var = @model.bool_var
    @expect_options.call(anything, :bool => var)
    @invoke_options.call(@operand, :reify => var)
  end

  it 'should translate reification with arbitrary bool operand' do
    op, bool_var = general_bool_operand(@model)
    @expect_options.call(anything, :bool => bool_var)
    @invoke_options.call(@operand, :reify => op)
  end
  
  it 'should raise errors for reification variables of incorrect type' do
    lambda do 
      @invoke_options.call(@operand, :reify => 'foo')
    end.should raise_error(TypeError)
  end
end

# Requires @operand, @invoke_options and @expect_options.
describe 'reifiable int constraint', :shared => true do
  it_should_behave_like 'int constraint with default options'
  it_should_behave_like 'constraint with reification option'
end

# Requires @operand, @invoke_options and @expect_options.
describe 'reifiable bool constraint', :shared => true do
  it_should_behave_like 'bool constraint with default options'
  it_should_behave_like 'constraint with reification option'
end

# TODO test arbitrary int operands as target.

# Requires @invoke_options, @expect_options, @model
describe 'int constraint', :shared => true do
  it 'should handle arbitrary int operands' do
    op, int_var = general_int_operand(@model)
    @expect_options.call(@model.allow_space_access{ int_var.bind }, {})
    @invoke_options.call(op, {})
  end
end

# Requires @invoke_options, @expect_options, @model
describe 'bool constraint', :shared => true do
  it 'should handle arbitrary bool operands' do
    op, bool_var = general_bool_operand(@model)
    @expect_options.call(@model.allow_space_access{ bool_var.bind }, {})
    @invoke_options.call(op, {})
  end
end

# Requires @operand, @invoke_options, @expect_options, @model
describe 'non-reifiable int constraint', :shared => true do
  it 'should raise errors if reification is used' do
    lambda do 
      @invoke_options.call(@operand, :reify => @model.bool_var)
    end.should raise_error(ArgumentError)
  end

  it_should_behave_like 'int constraint with default options'
end

# Requires @operand, @invoke_options, @expect_options, @model
describe 'non-reifiable bool constraint', :shared => true do
  it 'should raise errors if reification is used' do
    lambda do 
      @invoke_options.call(@operand, :reify => @model.bool_var)
    end.should raise_error(ArgumentError)
  end

  it_should_behave_like 'bool constraint with default options'
end

# Requires @operand, @invoke_options and @expect_options.
describe 'int constraint with default options', :shared => true do
  it 'should raise errors for unrecognized options' do
    lambda do 
      @invoke_options.call(@operand, :does_not_exist => :foo) 
    end.should raise_error(ArgumentError)
  end

  it_should_behave_like 'constraint with strength option'
  it_should_behave_like 'constraint with kind option'
  it_should_behave_like 'int constraint'
end

# Requires @operand, @invoke_options and @expect_options.
describe 'bool constraint with default options', :shared => true do
  it 'should raise errors for unrecognized options' do
    lambda do 
      @invoke_options.call(@operand, :does_not_exist => :foo)
    end.should raise_error(ArgumentError)
  end

  it_should_behave_like 'constraint with strength option'
  it_should_behave_like 'constraint with kind option'
  it_should_behave_like 'bool constraint'
end

# Requires @invoke_options and @operand.
describe 'set constraint', :shared => true do
  it 'should not accept strength option' do
    lambda do 
      @invoke_options.call(@operand, :strength => :default)
    end.should raise_error(ArgumentError)
  end
  
  it 'should not accept kind option' do
    lambda do 
      @invoke_options.call(@operand, :kind => :default)
    end.should raise_error(ArgumentError)
  end
  
  it 'should raise errors for unrecognized options' do
    lambda do 
      @invoke_options.call(@operand, :does_not_exist => :foo) 
    end.should raise_error(ArgumentError)
  end
end

# Requires @operand, @invoke_options and @model.
describe 'non-reifiable set constraint', :shared => true do
  it 'should not accept reification option' do
    bool = @model.bool_var
    lambda do 
      @invoke_options.call(@operand, :reify => bool)
    end.should raise_error(ArgumentError)
  end
  
  it_should_behave_like 'set constraint'
end

# Requires @operand, @invoke_options, @expect_options and @model.
describe 'reifiable set constraint', :shared => true do
  it_should_behave_like 'set constraint'
  it_should_behave_like 'constraint with reification option'
end




# Several of these shared specs requires one or more of the following instance 
# variables to be used: 
# [@operand]  The operand that is being tested.
# [@model]    The model that defines the context in which the test is
#             conducted.
# [@property_types]  An array of symbols signaling what types of
#                    arguments @select_property accepts. The symbols
#                    must be one of: :int, :bool, :set, :int_enum,
#                    :bool_enum, :set_enum, :fixnum_enum.
# [@select_property] A proc that selects the property under test. It
#                    should take at least one argument: the operand that
#                    the property should be selected from.
# [@selected_property] The resulting operand of the property. It should
#                      be constrained to the degree that it has a
#                      non-maximal domain.
#


# Requires @operand and @model.
describe 'int var operand', :shared => true do
  it 'should implement #model' do
    @operand.model.should be_kind_of(Gecode::Model)
  end

  it 'should implement #to_int_var' do
    int_var = @operand.to_int_var
    int_var.should be_kind_of(Gecode::FreeIntVar)
    @model.solve!
    (int_var.min..int_var.max).should_not equal(Gecode::Model::LARGEST_INT_DOMAIN)
  end

  it 'should implement #must' do
    receiver = @operand.must
    receiver.should be_kind_of(Gecode::Constraints::Int::IntVarConstraintReceiver)
  end
end

# Requires @model, @property_types and @select_property.
describe 'property that produces int operand', :shared => true do
  def produce_general_arguments(property_types)
    operands = []
    variables = []
    property_types.each do |type|
      op, var = eval "general_#{type}_operand(@model)"
      operands << op
      variables << var
    end
    return operands, variables
  end

  it 'should produce int operand' do
    operands, variables = produce_general_arguments(@property_types)
    operand = @select_property.call(*operands)

    # Test the same invariants as in the test for int var operands.
    operand.model.should be_kind_of(Gecode::Model)

    int_var = operand.to_int_var
    int_var.should be_kind_of(Gecode::FreeIntVar)

    receiver = operand.must
    receiver.should be_kind_of(
      Gecode::Constraints::Int::IntVarConstraintReceiver)
  end

  it 'should raise errors if parameters of the incorrect type are given' do
    operands, variables = produce_general_arguments(@property_types)
    (1...operands.size).each do |i|
      bogus_operands = operands.clone
      bogus_operands[i] = Object.new
      lambda do
        @select_property.call(*bogus_operands)
      end.should raise_error(TypeError)
    end
  end
end

# Requires @model, @property_types, @select_property and
# @selected_property.
#
# These properties should only short circuit equality when there is no
# negation nor reification and the right hand side is an int operand.
describe 'property that produces int operand by short circuiting equality', :shared => true do
  it 'should give the same solution regardless of whether short circuit was used' do
    int_operand = @selected_property
    direct_int_var = int_operand.to_int_var
    indirect_int_var = @model.int_var
    @selected_property.must == indirect_int_var
    @model.solve!

    direct_int_var.should_not have_domain(Gecode::Model::LARGEST_INT_DOMAIN)
    direct_int_var.should have_domain(indirect_int_var.domain)
  end

  it 'should not place rel constraints when it should be short circuiting' do
    Gecode::Raw.should_not_receive(:rel)
    @selected_property.must == @model.int_var
    @model.solve!
  end

  it 'should not short circuit when negation is used' do
    Gecode::Raw.should_receive(:rel)
    @selected_property.must_not == @model.int_var
    @model.solve!
  end

  it 'should not short circuit when reification is used' do
    Gecode::Raw.should_receive(:rel)
    @selected_property.must.equal(@model.int_var, :reify => @model.bool_var)
    @model.solve!
  end

  it 'should not short circuit when the right hand side is not a operand' do
    Gecode::Raw.should_receive(:rel)
    @selected_property.must == 17
    @model.solve!
  end

  it 'should not short circuit when equality is not used' do
    Gecode::Raw.should_receive(:rel)
    @selected_property.must > @model.int_var
    @model.solve!
  end

  it 'should raise error when the right hand side is of illegal type' do
    lambda do
      @selected_property.must == 'foo'
    end.should raise_error(TypeError)
  end

  it_should_behave_like 'property that produces int operand'
end

# Requires @model, @property_types and @select_property.
# 
# These properties should short circuit all comparison relations
# even when negated and when fixnums are used as right hand side.
describe 'property that produces int operand by short circuiting relations', :shared => true do
  Gecode::Constraints::Util::RELATION_TYPES.keys.each do |relation|
    it "should give the same solution regardless of whether short circuit #{relation} was used" do
      direct_int_var = @model.int_var
      @selected_property.to_int_var.must.method(relation).call direct_int_var
      indirect_int_var = @model.int_var
      @selected_property.must.method(relation).call indirect_int_var
      @model.solve!

      direct_int_var.should_not have_domain(Gecode::Model::LARGEST_INT_DOMAIN)
      direct_int_var.should have_domain(indirect_int_var.domain)
    end

    it "should short circuit #{relation}" do
      Gecode::Raw.should_not_receive(:rel)
      @selected_property.must.method(relation).call @model.int_var
      @model.solve!
    end

    it "should short circuit negated #{relation}" do
      Gecode::Raw.should_not_receive(:rel)
      @selected_property.must_not.method(relation).call @model.int_var
      @model.solve!
    end

    it "should short circuit #{relation} when reification is used" do
      Gecode::Raw.should_not_receive(:rel)
      @selected_property.must.method(relation).call(@model.int_var, :reify => @model.bool_var)
      @model.solve!
    end

    it "should short circuit #{relation} even when the right hand side is a fixnum" do
      Gecode::Raw.should_not_receive(:rel)
      @selected_property.must.method(relation).call(2)
      @model.solve!
    end

    it "should raise error when the #{relation} right hand side is of illegal type" do
      lambda do
        @selected_property.must.method(relation).call('foo')
      end.should raise_error(TypeError)
    end
  end

  it_should_behave_like 'property that produces int operand'
end

  # TODO
  # * Test &, |, implies, ^ as properties.
  #


# Requires @expect_relation, @invoke_relation and @target.
describe 'composite set constraint', :shared => true do
  Gecode::Constraints::Util::SET_RELATION_TYPES.each_pair do |relation, type|
    it "should translate #{relation} with constant target" do
      @expect_relation.call(type, [1], false)
      @invoke_relation.call(relation, [1], false)
    end
  end
  
  Gecode::Constraints::Util::SET_RELATION_TYPES.each_pair do |relation, type|
    it "should translate #{relation} with variable target" do
      @expect_relation.call(type, @target, false)
      @invoke_relation.call(relation, @target, false)
    end
  end
  
  Gecode::Constraints::Util::NEGATED_SET_RELATION_TYPES.each_pair do |relation, type|
    it "should translate negated #{relation} with constant target" do
      @expect_relation.call(type, [1], true)
      @invoke_relation.call(relation, [1], true)
    end
  end
  
  Gecode::Constraints::Util::NEGATED_SET_RELATION_TYPES.each_pair do |relation, type|
    it "should translate negated #{relation} with variable target" do
      @expect_relation.call(type, @target, true)
      @invoke_relation.call(relation, @target, true)
    end
  end

  it 'should raise error if the target is of the wrong type' do
    lambda do 
      @invoke_relation.call(:==, 'hello', false)
    end.should raise_error(TypeError) 
  end
end







# Help methods for the GecodeR specs. 
module GecodeR::Specs
  module SetHelper
    module_function
  
    # Returns the arguments that should be used in a partial mock to expect the
    # specified constant set (possibly an array of arguments).
    def expect_constant_set(constant_set)
      if constant_set.kind_of? Range
        return constant_set.first, constant_set.last
      elsif constant_set.kind_of? Fixnum
        constant_set
      else
        an_instance_of(Gecode::Raw::IntSet)
      end
    end
  end

  module GeneralHelper
    module_function

    # Helper for creating @expect_option. Creates a method that takes an
    # operand variable and a hash that may have values for the keys :icl
    # (ICL_*), :pk (PK_*), and :bool (reification variable).
    # Expectations corresponding to the hash values are given to the
    # specified block in the order of operand_variable, icl, pk and
    # bool. Default values are provided if the hash doesn't specify
    # anything else.
    def option_expectation(&block)
      lambda do |operand_var, hash|
        bool = hash[:bool]
        # We loosen the expectation some to avoid practical problems with expecting
        # specific variables not under our control.
        bool = an_instance_of(Gecode::Raw::BoolVar) unless bool.nil?
        yield(operand_var, hash[:icl] || Gecode::Raw::ICL_DEF,
          hash[:pk]  || Gecode::Raw::PK_DEF,
          bool)
      end
    end

    # Produces a base operand that can be used to mock specific types of
    # operands.
    def general_operand_base(model)
      mock_op_class = Class.new
      mock_op_class.class_eval do
        attr :model

        def bind
          raise 'Bind should not be called directly for an operand.'
        end
      end
      op = mock_op_class.new
      op.instance_eval do
        @model = model
      end
      return op
    end

    # Produces a general int operand. The method returns two objects: 
    # the operand itself and the variable it returns when #to_int_var
    # is called.
    def general_int_operand(model)
      op = general_operand_base(model)
      
      int_var = @model.int_var
      class <<op
        include Gecode::Constraints::Int::IntVarOperand
        attr :model
      end
      op.stub!(:to_int_var).and_return int_var

      return op, int_var
    end

    # Produces a general bool operand. The method returns two objects: 
    # the operand itself and the variable it returns when #to_bool_var
    # is called.
    def general_bool_operand(model)
      op = general_operand_base(model)
      
      bool_var = @model.bool_var
      class <<op
        include Gecode::Constraints::Int::IntVarOperand
        attr :model
      end
      op.stub!(:to_bool_var).and_return bool_var

      return op, bool_var
    end
    
    # Produces a general int enum operand. The method returns two objects: 
    # the operand itself and the variable it returns when #to_int_enum
    # is called.
    def general_int_enum_operand(model)
      op = general_operand_base(model)
      
      int_enum = @model.int_var_array(5)
      class <<op
        include Gecode::Constraints::IntEnum::IntEnumOperand
        attr :model
      end
      op.stub!(:to_int_enum).and_return int_enum

      return op, int_enum
    end

    # Produces a general fixnum enum operand. The method returns two objects: 
    # the operand itself and the variable it returns when #to_fixnum_enum
    # is called.
    def general_fixnum_enum_operand(model)
      op = general_operand_base(model)
      
      fixnum_enum = model.wrap_enum([1, -4, 9, 4, 0])
      class <<op
        include Gecode::Constraints::FixnumEnum::FixnumEnumOperand
        attr :model
      end
      op.stub!(:to_fixnum_enum).and_return fixnum_enum

      return op, fixnum_enum
    end
  end
end
include GecodeR::Specs::GeneralHelper
