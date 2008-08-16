module Gecode::Constraints::IntEnum
  module IntEnumOperand
    # Produces an integer operand representing the maximum value of the 
    # integer variables in this operand.
    #
    # ==== Examples 
    #
    #   # The maximum of +int_enum+.
    #   int_enum.max
    def max
      Arithmetic::IntEnumMaxOperand.new(@model, self)
    end
    
    # Produces an integer operand representing the minimum value of the 
    # integer variables in this operand.
    #
    # ==== Examples 
    #
    #   # The minimum of +int_enum+.
    #   int_enum.min
    def min
      Arithmetic::IntEnumMinOperand.new(@model, self)
    end
  end

  # A module that gathers the classes and modules used by arithmetic 
  # constraints.
  module Arithmetic #:nodoc:
    class IntEnumMaxOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, int_enum)
        super model
        @int_enum = int_enum
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        enum = @int_enum.to_int_enum
        if constrain
          int_operand.must_be.in enum.domain_range
        end
        
        Gecode::Raw::max(@model.active_space, enum.bind_array, 
          int_operand.to_int_var.bind, *propagation_options)
      end
    end
    
    class IntEnumMinOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, int_enum)
        super model
        @int_enum = int_enum
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        enum = @int_enum.to_int_enum
        if constrain
          int_operand.must_be.in enum.domain_range
        end
        
        Gecode::Raw::min(@model.active_space, enum.bind_array, 
          int_operand.to_int_var.bind, *propagation_options)
      end
    end
  end
end
