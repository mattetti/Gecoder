describe Gecode::Constraints::Set::Connection, ' (include)' do
  before do
    @model = Gecode::Model.new
    @set = @model.set_var([], 2..5)
    @array = @model.int_var_array(4, 0..9)
    @array.must_be.distinct
    @model.branch_on @array
    #@model.branch_on @model.wrap_enum([@set])
    
    @expect = lambda do |rhs, strength, reif_var|
      @model.allow_space_access do
        Gecode::Raw.should_receive(:match).once.with(
          an_instance_of(Gecode::Raw::Space), 
          an_instance_of(Gecode::Raw::SetVar), 
          an_instance_of(Gecode::Raw::IntVarArray))
      end
    end
    
    @expect_options = option_expectation do |strength, kind, reif_var|
      @expect.call(@array, strength, reif_var)
    end
    @invoke_options = lambda do |hash|
      @set.must.include(@array, hash)
      @model.solve!
    end
  end
  
  it 'should translate to a match constraint' do
    @expect_options.call({})
    @set.must.include @array
    @model.solve!
  end
  
  it 'should constrain the variables to be included in the set' do
    @set.must.include @array
    @model.solve!.should_not be_nil
    @array.all?{ |x| @set.lower_bound.include? x.value }.should be_true
  end
  
  it 'should raise error if the right hand side is not an array of variables' do
    lambda{ @set.must.include 'hello' }.should raise_error(TypeError)
  end
  
  it 'should raise error if negated' do
    lambda{ @set.must_not.include @array }.should raise_error(
      Gecode::MissingConstraintError)
  end
  
  it_should_behave_like 'non-reifiable set constraint'
end
