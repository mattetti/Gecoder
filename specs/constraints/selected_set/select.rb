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

describe Gecode::Constraints::SetEnum::Selection, ' (union)' do
  include GecodeR::Specs::SetHelper

  before do
    @model = SelectionSampleProblem.new
    @sets = @model.sets
    @set = @model.set
    @target = @model.target
    @model.branch_on @model.wrap_enum([@target, @set])
    @stub = @sets[@set].union
    
    @property_types = [:set_enum, :int]
    @select_property = lambda do |set_enum, int|
      set_enum[int]
    end
    @selected_property = @sets[@index]
    @constraint_class = Gecode::Constraints::BlockConstraint
  end
  
  it 'should constrain the selected union of an enum of sets' do
    @sets[@set].union.must_be.subset_of([5,7,9])
    @sets[@set].union.must_be.superset_of([5])
    @model.solve!
    union = @set.value.inject([]) do |union, i|
      union += @sets[i].value.to_a
    end.uniq
    union.should include(5)
    (union - [5,7,9]).should be_empty
  end
  
  it_should_behave_like 'selection constraint'
end

describe Gecode::Constraints::SetEnum::Selection, ' (intersection)' do
  include GecodeR::Specs::SetHelper

  before do
    @model = SelectionSampleProblem.new
    @sets = @model.sets
    @set = @model.set
    @target = @model.target
    @model.branch_on @model.wrap_enum([@target, @set])
    @stub = @sets[@set].intersection
  end
  
  it 'should constrain the selected intersection of an enum of sets' do
    @sets[@set].intersection.must_be.subset_of([5,7,9])
    @sets[@set].intersection.must_be.superset_of([5])
    @model.solve!
    intersection = @set.value.inject(nil) do |intersection, i|
      elements = @sets[i].value.to_a
      next elements if intersection.nil?
      intersection &= elements
    end.uniq
    intersection.should include(5)
    (intersection - [5,7,9]).should be_empty
  end
  
  it_should_behave_like 'selection constraint'
end

describe Gecode::Constraints::SetEnum::Selection, ' (intersection with universe)' do
  include GecodeR::Specs::SetHelper

  before do
    @model = SelectionSampleProblem.new
    @sets = @model.sets
    @set = @model.set
    @target = @model.target
    @model.branch_on @model.wrap_enum([@target, @set])
    @universe = [1,2]
    @stub = @sets[@set].intersection(:with => @universe)
    
    @expect_constrain_equal = lambda do
      Gecode::Raw.should_receive(:selectInterIn).once.with( 
        an_instance_of(Gecode::Raw::Space),
        an_instance_of(Gecode::Raw::SetVarArray), 
        an_instance_of(Gecode::Raw::SetVar), 
        an_instance_of(Gecode::Raw::SetVar),
        an_instance_of(Gecode::Raw::IntSet))
    end
  end
  
  it 'should constrain the selected intersection of an enum of sets in a universe' do
    @sets[@set].intersection(:with => @universe).must_be.subset_of([2])
    @model.solve!
    intersection = @set.value.inject(@universe) do |intersection, i|
      intersection &= @sets[i].value.to_a
    end.uniq
    intersection.should include(2)
    (intersection - [1,2]).should be_empty
  end
  
  it 'should allow the universe to be specified as a range' do
    @sets[@set].intersection(:with => 1..2).must_be.subset_of([2])
    @model.solve!
    intersection = @set.value.inject(@universe) do |intersection, i|
      intersection &= @sets[i].value.to_a
    end.uniq
    intersection.should include(2)
    (intersection - [1,2]).should be_empty
  end
  
  it 'should raise error if unknown options are specified' do
    lambda do
      @sets[@set].intersection(:does_not_exist => nil).must_be.subset_of([2])
    end.should raise_error(ArgumentError)
  end
  
  it 'should raise error if the universe is of the wrong type' do
    lambda do
      @sets[@set].intersection(:with => 'foo').must_be.subset_of([2])
    end.should raise_error(TypeError)
  end
  
  it_should_behave_like 'selection constraint'
end


