# A module containing constraints that have enumerations of instances of
# Fixnum as left hand side.
module Gecode::Constraints::FixnumEnum
  # Describes a fixnum enumeration operand. Classes that mix in
  # FixnumEnumOperand must define #to_fixnum_enum .
  module FixnumEnumOperand
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
      if Gecode::FixnumEnum.instance_methods.include? method.to_s
        # Delegate to the fixnum enum.
        to_fixnum_enum.method(method).call(*args)
      else
        super
      end
    end

    private
  
    def construct_receiver(params)
      raise NotImplementedError, 'Fixnum enums do not have constraints.'
    end
  end
end

require 'gecoder/interface/constraints/fixnum_enum/element'
require 'gecoder/interface/constraints/fixnum_enum/operation'
