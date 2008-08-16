# A module containing constraints that have enumerations of set variables as 
# left hand side.
module Gecode::Constraints::SetEnum #:nodoc:
  # A SetEnumOperand is a enumeration of SetOperand on which the
  # constraints defined in SetEnumConstraintReceiver can be placed.
  #
  # Enumerations of set operands can be created either by using
  # Gecode::Model#set_var_array and Gecode::Model#set_var_matrix, or
  # by wrapping an existing enumeration containing SetOperand using
  # Gecode::Model#wrap_enum. The enumerations, no matter how they were
  # created, all respond to the properties defined by SetEnumOperand.
  #
  # ==== Examples 
  #
  # Produces an array of five set operands, with greatest lower bound
  # {0} and least upper bound {0, 1, 2}, inside a problem formulation
  # using Gecode::Model#set_var_array:
  #
  #   set_enum = set_var_array(5, 0, 1..2)
  #
  # Uses Gecode::Model#wrap_enum inside a problem formulation to create
  # a SetEnumOperand from an existing enumeration containing the
  # set operands +set_operand1+ and +set_operand2+:
  #
  #   set_enum = wrap_enum([set_operand1, set_operand2])
  #   
  #--
  # Classes that mix in SetEnumOperand must define #model and
  # #to_set_enum .
  module SetEnumOperand
    include Gecode::Constraints::Operand 

    def method_missing(method, *args) #:nodoc:
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

  # SetEnumConstraintReceiver contains all constraints that can be
  # placed on a SetEnumOperand.
  #
  # Constraints are placed by calling SetEnumOperand#must (or any other
  # of the variations defined in Operand), which produces a 
  # SetEnumConstraintReceiver from which the desired constraint can be used.
  #
  # ==== Examples 
  #
  # Constrains +set_enum+ to channel +int_enum+ by using 
  # SetEnumConstraintReceiver#channel:
  #
  #   set_enum.must.channel set_enum
  #
  # Constrains each pair of set operands in +set_enum+ to at most share
  # one element. Also constrains each set to have size 17. Uses 
  # SetEnumConstraintReceiver#at_most_share_one_element.
  #
  #   set_enum.must.at_most_share_one_element(:size => 17)
  #
  class SetEnumConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is a set enum operand.
    def initialize(model, params) #:nodoc:
      super
      
      unless params[:lhs].respond_to? :to_set_enum
        raise TypeError, 'Must have set enum operand as left hand side.'
      end
    end
  end
end

require 'gecoder/interface/constraints/set_enum/channel'
require 'gecoder/interface/constraints/set_enum/distinct'
require 'gecoder/interface/constraints/set_enum/select'
require 'gecoder/interface/constraints/set_enum/operation'
