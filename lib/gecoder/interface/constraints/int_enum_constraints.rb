# A module containing constraints that have enumerations of integer 
# variables as left hand side.
module Gecode::Constraints::IntEnum
  # Describes an integer variable operand. Classes that mix in
  # IntVarEnumOperand must define #model .
  module IntVarEnumOperand
    include Gecode::Constraints::Operand 

    private

    def construct_receiver(params)
      params.update(:lhs => self)
      IntVarEnumConstraintReceiver.new(@model, params)
    end
  end

  # Describes a constraint receiver for integer variables.
  class IntVarEnumConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an int enum
    # operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_int_var_array
        raise TypeError, 'Must have int var enum operand as left hand side.'
      end
    end
  end
end

#require 'gecoder/interface/constraints/int_enum/distinct'
#require 'gecoder/interface/constraints/int_enum/equality'
#require 'gecoder/interface/constraints/int_enum/channel'
require 'gecoder/interface/constraints/int_enum/element'
#require 'gecoder/interface/constraints/int_enum/count'
#require 'gecoder/interface/constraints/int_enum/sort'
#require 'gecoder/interface/constraints/int_enum/arithmetic'
#require 'gecoder/interface/constraints/int_enum/extensional'
