# A module containing constraints that have set.elements as left hand
# side.
module Gecode::Constraints::SetElements
  # Describes a selected set operand. The operand is produced using the
  # set property #elements . I.e. the following produces a set elements
  # operand.
  # 
  #   set.elements
  class SetElementsOperand
    include Gecode::Constraints::Operand 

    # Constructs a new set elements operand +set+.
    def initialize(set)
      unless set.respond_to? :to_set_var
        raise TypeError, "Expected set var operand, got #{set.class}."
      end

      @set = set
    end

    # Returns the set operand that makes up the set elements operand.
    def to_set_elements
      return @set
    end

    def model
      @set.model
    end

    private

    def construct_receiver(params)
      SetElementsConstraintReceiver.new(model, params)
    end
  end

  # Describes a constraint receiver for set elements operands.
  class SetElementsConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is set elements operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_set_elements
        raise TypeError, 'Must have set elements operand as left hand side.'
      end
    end
  end
end

# require 'gecoder/interface/constraints/selected_set/select'
