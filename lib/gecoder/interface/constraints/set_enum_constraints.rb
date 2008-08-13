# A module containing constraints that have enumerations of set variables as 
# left hand side.
module Gecode::Constraints::SetEnum
  # Describes a set variable enumeration operand. Classes that mix in
  # IntEnumOperand must define #model and #to_set_enum .
  module SetEnumOperand
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
      if Gecode::SetEnum.instance_methods.include? method.to_s
        # Delegate to the set enum.
        to_set_enum.method(method).call(*args)
      else
        super
      end
    end

    private

    def construct_receiver(params)
      Gecode::Constraints::SetEnum::SetEnumConstraintReceiver.new(@model, params)
    end
  end

  # Describes a constraint receiver for enumerations of set operands.
  class SetEnumConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is a set enum operand.
    def initialize(model, params)
      super
      
      unless params[:lhs].respond_to? :to_set_enum
        raise TypeError, 'Must have set enum operand as left hand side.'
      end
    end
  end
end

#require 'gecoder/interface/constraints/set_enum/channel'
require 'gecoder/interface/constraints/set_enum/distinct'
require 'gecoder/interface/constraints/set_enum/select'
require 'gecoder/interface/constraints/set_enum/operation'
