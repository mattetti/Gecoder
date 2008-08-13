# A module containing constraints that have enumerations of boolean 
# operands as left hand side.
module Gecode::Constraints::BoolEnum
  # Describes an boolean variable enumeration operand. Classes that mix in
  # BoolEnumOperand must define #model and #to_bool_enum .
  module BoolEnumOperand
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
      if Gecode::BoolEnum.instance_methods.include? method.to_s
        # Delegate to the bool enum.
        to_bool_enum.method(method).call(*args)
      else
        super
      end
    end

    private

    def construct_receiver(params)
      BoolEnumConstraintReceiver.new(@model, params)
    end
  end

  # Describes a constraint receiver for enumerations of boolean operands.
  class BoolEnumConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an bool enum
    # operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_bool_enum
        raise TypeError, 'Must have bool enum operand as left hand side.'
      end
    end
  end
end

require 'gecoder/interface/constraints/bool_enum/relation'
require 'gecoder/interface/constraints/bool_enum/extensional'
#require 'gecoder/interface/constraints/bool_enum/channel'
