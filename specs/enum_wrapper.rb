require File.dirname(__FILE__) + '/spec_helper'

describe Gecode::Model, ' (enum wrapping)' do
  before do
    @model = Gecode::Model.new
    @bool = @model.bool_var
    @int = @model.int_var(1..2)
  end

  it 'should only allow enumerables to be wrapped' do
    lambda do
      @model.wrap_enum(17) 
    end.should raise_error(TypeError)
  end

  it 'should allow enumerables of bool variables to be wrapped' do
    lambda do
      enum = [@bool]
      @model.wrap_enum(enum) 
    end.should_not raise_error
  end
  
  it 'should allow enumerables of int variables to be wrapped' do
    lambda do
      enum = [@int]
      @model.wrap_enum(enum) 
    end.should_not raise_error
  end
  
  it 'should allow enumerables of fixnums to be wrapped' do
    lambda do
      enum = [17]
      @model.wrap_enum(enum) 
    end.should_not raise_error
  end
  
  it 'should not allow empty enumerables to be wrapped' do
    lambda do 
      @model.wrap_enum([]) 
    end.should raise_error(ArgumentError)
  end
  
  it 'should not allow enumerables without variables or fixnums to be wrapped' do
    lambda do 
      @model.wrap_enum(['foo']) 
    end.should raise_error(TypeError)
  end
  
  it 'should not allow enumerables with only some variables to be wrapped' do
    lambda do 
      enum = [@bool, 'foo']
      @model.wrap_enum(enum) 
    end.should raise_error(TypeError)
  end
  
  it 'should not allow enumerables with mixed types of variables to be wrapped' do
    lambda do 
      enum = [@bool, @int]
      @model.wrap_enum(enum) 
    end.should raise_error(TypeError)
  end
end

describe Gecode::IntEnumMethods do
  before do
    @model = Gecode::Model.new
    @int_enum = @model.int_var_array(3, 0..1)
  end
  
  it 'should convert to an int var array' do
    @model.allow_space_access do
      @int_enum.to_int_var_array.should be_kind_of(Gecode::Raw::IntVarArray)
    end
  end
  
  it 'should compute the smallest domain range' do
    @int_enum.domain_range.should == (0..1)
    (@int_enum << @model.int_var(-4..4)).domain_range.should == (-4..4)
  end
end

describe Gecode::BoolEnumMethods do
  before do
    @model = Gecode::Model.new
    @bool_enum = @model.bool_var_array(3)
  end
  
  it 'should convert to a bool var array' do
    @model.allow_space_access do
      @bool_enum.to_bool_var_array.should be_kind_of(Gecode::Raw::BoolVarArray)
    end
  end
end

describe Gecode::SetEnumMethods do
  before do
    @model = Gecode::Model.new
    @set_enum = @model.set_var_array(3, [0], 0..1)
  end
  
  it 'should convert to a set var array' do
    @model.allow_space_access do
      @set_enum.to_set_var_array.should be_kind_of(Gecode::Raw::SetVarArray)
    end
  end
end

describe Gecode::FixnumEnumMethods do
  before do
    @model = Gecode::Model.new
    @enum = @model.instance_eval{ wrap_enum([7, 14, 17, 4711]) }
  end
  
  it 'should compute the smallest domain range' do
    @enum.domain_range.should == (7..4711)
  end
end