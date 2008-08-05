# A module containing constraints that have enumerations of instances of
# Fixnum as left hand side.
module Gecode::Constraints::FixnumEnum
  # Describes a fixnum enumeration operand. Classes that mix in
  # FixnumEnumOperand must define #to_fixnum_enum .
  module FixnumEnumOperand
    include Gecode::Constraints::Operand 

    def model
      raise NotImplementedError, 'Fixnum enums are not connected to any model.'
    end

    private
  
    def constraint_receiver
      raise NotImplementedError, 'Fixnum enums do not have constraints.'
    end
  end
end

require 'gecoder/interface/constraints/fixnum_enum/element'
