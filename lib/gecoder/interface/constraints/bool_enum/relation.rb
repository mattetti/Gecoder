module Gecode::Constraints::BoolEnum
  module BoolEnumOperand
    # Produces a boolean operand that represents the conjunction (AND) of all
    # boolean variables in this enumeration.
    #
    # == Examples
    #
    #   # Conjunction of all elements in +bool_enum+.
    #   bool_enum.conjunction
    def conjunction
      Relation::BoolEnumConjunctionOperand.new(@model, self)
    end
    
    # Produces a boolean operand that represents the disjunction (OR) of all
    # boolean variables in this enumeration.
    #
    # == Examples
    #
    #   # Disjunction of all elements in +bool_enum+.
    #   bool_enum.disjunction
    def disjunction
      Relation::BoolEnumDisjunctionOperand.new(@model, self)
    end
  end

  # A module that gathers the classes and modules used by boolean enumeration 
  # relation constraints.
  module Relation #:nodoc:
    class BoolEnumConjunctionOperand < Gecode::Constraints::Bool::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, bool_enum)
        super model
        @enum = bool_enum
      end

      def constrain_equal(bool_operand, constrain_domain, propagation_options)
        Gecode::Raw::rel(@model.active_space, Gecode::Raw::BOT_AND,
          @enum.to_bool_enum.bind_array, bool_operand.to_bool_var.bind, 
          *propagation_options)
      end
    end
    
    class BoolEnumDisjunctionOperand < Gecode::Constraints::Bool::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, bool_enum)
        super model
        @enum = bool_enum
      end

      def constrain_equal(bool_operand, constrain_domain, propagation_options)
        Gecode::Raw::rel(@model.active_space, Gecode::Raw::BOT_OR,
          @enum.to_bool_enum.bind_array, bool_operand.to_bool_var.bind, 
          *propagation_options)
      end
    end
  end
end
