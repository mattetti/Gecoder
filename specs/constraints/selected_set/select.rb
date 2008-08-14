describe Gecode::Constraints::SetEnum::Selection, ' (disjoint)' do
  include GecodeR::Specs::SetHelper

  before do
    @model = SelectionSampleProblem.new
    @sets = @model.sets
    @set = @model.set
    @target = @model.target
    @model.branch_on @model.wrap_enum([@target, @set])
    
    @expect = lambda do |index|
      Gecode::Raw.should_receive(:selectDisjoint)
    end
    
    # For options spec.
    @invoke_options = lambda do |hash|
      @sets[@set].must_be.disjoint(hash)
      @model.solve!
    end
    @expect_options = option_expectation do |strength, kind, reif_var|
      @expect.call(@set)
    end
  end
  
  it 'should constrain the selected sets to be disjoint' do
    @sets[0].must_be.superset_of([7,8])
    @sets[1].must_be.superset_of([5,7,9])
    @sets[2].must_be.superset_of([6,8,10])
    @sets[@set].must_be.disjoint
    @set.size.must > 1
    @model.solve!.should_not be_nil
    
    @set.value.to_a.sort.should == [1,2]
  end
  
  it 'should not allow negation' do
    lambda{ @sets[@set].must_not_be.disjoint }.should raise_error(
      Gecode::MissingConstraintError) 
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end

