require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/constraint_helper'

describe Gecode::Constraints::Int::Domain, ' (non-range)' do
  before do
    @model = Gecode::Model.new
    @domain = 0..3
    @operand = @x = @model.int_var(@domain)
    @non_range_domain = [1, 3]
    
    @invoke_options = lambda do |op, hash| 
      op.must_be.in(@non_range_domain, hash) 
      @model.solve!
    end
    @expect_options = option_expectation do |op_var, strength, kind, reif_var|
      @model.allow_space_access do
        if reif_var.nil?
          Gecode::Raw.should_receive(:dom).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::IntVar), 
            an_instance_of(Gecode::Raw::IntSet), 
            strength, kind)
        else
          Gecode::Raw.should_receive(:dom).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::IntVar), 
            an_instance_of(Gecode::Raw::IntSet), 
            reif_var, strength, kind)
        end
      end
    end
  end
  
  it 'should handle negation' do
    @x.must_not_be.in @non_range_domain
    @model.solve!
    @x.should have_domain(@domain.to_a - @non_range_domain.to_a)
  end
  
  it 'should raise error if the right hand side is not an enumeration' do
    lambda{ @x.must_be.in 'hello' }.should raise_error(TypeError)
  end
  
  it_should_behave_like 'reifiable int constraint'
end

describe Gecode::Constraints::Int::Domain, ' (range)' do
  before do
    @model = Gecode::Model.new
    @domain = 0..3
    @operand = @x = @model.int_var(@domain)
    @range_domain = 1..2
    @three_dot_range_domain = 1...2
    
    @invoke_options = lambda do |op, hash| 
      op.must_be.in(@range_domain, hash) 
      @model.solve!
    end
    @expect_options = option_expectation do |op_var, strength, kind, reif_var|
      @model.allow_space_access do
        if reif_var.nil?
          Gecode::Raw.should_receive(:dom).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::IntVar), 
            @range_domain.first, @range_domain.last,
            strength, kind)
        else
          Gecode::Raw.should_receive(:dom).once.with(
            an_instance_of(Gecode::Raw::Space), 
            an_instance_of(Gecode::Raw::IntVar), 
            @range_domain.first, @range_domain.last,
            reif_var, strength, kind)
        end
      end
    end
  end

  it 'should translate domain constraints with three dot range domains' do
    Gecode::Raw.should_receive(:dom).once.with(
      an_instance_of(Gecode::Raw::Space), 
      an_instance_of(Gecode::Raw::IntVar), @three_dot_range_domain.first, 
      @three_dot_range_domain.last, Gecode::Raw::ICL_DEF, Gecode::Raw::PK_DEF)
    @x.must_be.in @three_dot_range_domain
    @model.solve!
  end
  
  it 'should handle negation' do
    @x.must_not_be.in @range_domain
    @model.solve!
    @x.should have_domain(@domain.to_a - @range_domain.to_a)
  end
  
  it 'should raise error if the right hand side is not an enumeration' do
    lambda{ @x.must_be.in 'hello' }.should raise_error(TypeError)
  end
  
  it_should_behave_like 'reifiable int constraint'
end
