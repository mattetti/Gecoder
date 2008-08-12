require File.dirname(__FILE__) + '/../constraint_helper'

describe Gecode::Constraints::Set::Relation, ' (elements)' do
  include GecodeR::Specs::SetHelper

  before do
    @model = Gecode::Model.new
    @set = @model.set_var([0], 0..2)
    @int_var = @model.int_var(0..2)
    @int_constant = 2
    @model.branch_on @model.wrap_enum([@set])
    @expect = lambda do |relation_type, rhs|
      @model.allow_space_access do
        if rhs.kind_of? Fixnum
          rhs = an_instance_of(Gecode::Raw::IntVar)
        end
        rhs = rhs.bind if rhs.respond_to? :bind
        Gecode::Raw.should_receive(:rel).once.with(
          an_instance_of(Gecode::Raw::Space), 
          an_instance_of(Gecode::Raw::SetVar), relation_type, 
          an_instance_of(Gecode::Raw::IntVar))
      end
    end
    
    @invoke_options = lambda do |hash|
      @set.elements.must_be.equal_to(@int_var, hash)
    end
  end
  
  Gecode::Constraints::Util::RELATION_TYPES.each_pair do |relation, type|
    it "should translate #{relation} with variable to relation constraint" do
      @expect.call(type, @int_var)
      @set.elements.must.send(relation, @int_var)
      @model.solve!
    end
    
    it "should translate #{relation} with constant to relation constraint" do
      @expect.call(type, @int_constant)
      @set.elements.must.send(relation, @int_constant)
      @model.solve!
    end
  end

  Gecode::Constraints::Util::NEGATED_RELATION_TYPES.each_pair do |relation, type|
    it "should translate negated #{relation} with variable to relation constraint" do
      @expect.call(type, @int_var)
      @set.elements.must_not.send(relation, @int_var)
      @model.solve!
    end
    
    it "should translate negated #{relation} with constant to relation constraint" do
      @expect.call(type, @int_constant)
      @set.elements.must_not.send(relation, @int_constant)
      @model.solve!
    end
  end
  
  it 'should constrain the elements of the set' do
    @set.elements.must <= @int_var
    @int_var.must == 0
    @model.solve!
    @set.should be_assigned
    @set.value.should include(0)
    @set.value.should_not include(1,2)
  end
  
  it 'should constrain the elements of the set (constant parameter)' do
    @set.elements.must <= 0
    @model.solve!
    @set.should be_assigned
    @set.value.should include(0)
    @set.value.should_not include(1,2)
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end
