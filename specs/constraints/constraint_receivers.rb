require File.dirname(__FILE__) + '/../spec_helper'

describe 'constraint receiver', :shared => true do
  it 'should raise error unless an operand of the correct type is given as lhs' do
    lambda do
      op = Object.new
      class <<op
        include Gecode::Constraints::Operand
      end
      @receiver.new(@model, {:lhs => op, :negate => false})
    end.should raise_error(TypeError)
  end
end

describe Gecode::Constraints::ConstraintReceiver do
  before do
    @model = Gecode::Model.new
  end

  it 'should raise error if the negate params is not given' do
    lambda do
      Gecode::Constraints::ConstraintReceiver.new(@model, {:lhs => nil})
    end.should raise_error(ArgumentError)
  end
    
  it 'should raise error if the lhs params is not given' do
    lambda do
      Gecode::Constraints::ConstraintReceiver.new(@model, {:lhs => nil})
    end.should raise_error(ArgumentError)
  end
end

describe Gecode::Constraints::Int::IntConstraintReceiver, ' (not subclassed)' do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::Int::IntConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::IntEnum::IntEnumConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::IntEnum::IntEnumConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::Bool::BoolConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::Bool::BoolConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::BoolEnum::BoolEnumConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::BoolEnum::BoolEnumConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::Set::SetConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::Set::SetConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::SelectedSet::SelectedSetConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::SelectedSet::SelectedSetConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::SetElements::SetElementsConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::SetElements::SetElementsConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end

describe Gecode::Constraints::SetEnum::SetEnumConstraintReceiver do
  before do
    @model = Gecode::Model.new
    @receiver = Gecode::Constraints::SetEnum::SetEnumConstraintReceiver
  end

  it_should_behave_like 'constraint receiver'
end
