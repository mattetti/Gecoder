# A module containing constraints that have set_enum[set] as left hand
# side.
module Gecode::Constraints::SelectedSet #:nodoc:
  # Describes a selected set operand. The operand is produced when the
  # indexing operation of a set enum operand is given a set operand.
  # I.e. the following produces a selected set operand:
  #
  #   set_enum[set]
  class SelectedSetOperand
    include Gecode::Constraints::Operand 

    # Constructs a new selected set operand from +set_enum+ and +set+.
    def initialize(set_enum, set) #:nodoc:
      unless set_enum.respond_to? :to_set_enum
        raise TypeError, "Expected set enum operand, got #{set_enum.class}."
      end
      unless set.respond_to? :to_set_var
        raise TypeError, "Expected set operand, got #{set.class}."
      end

      @set_enum = set_enum
      @set = set
    end

    # Returns the set enum and set that make up the selected set
    # operand.
    def to_selected_set
      return @set_enum, @set
    end

    def model
      @set_enum.model
    end

    private

    def construct_receiver(params)
      SelectedSetConstraintReceiver.new(model, params)
    end
  end

  # Describes a constraint receiver for selected set operands.
  class SelectedSetConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is a selected set operand.
    def initialize(model, params) #:nodoc:
      super

      unless params[:lhs].respond_to? :to_selected_set
        raise TypeError, 'Must have selected set operand as left hand side.'
      end
    end
  end
end

require 'gecoder/interface/constraints/selected_set/select'
