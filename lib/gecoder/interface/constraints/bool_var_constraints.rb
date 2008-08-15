# A module that deals with the operands, properties and constraints of
# boolean variables.
module Gecode::Constraints::Bool #:nodoc:
  # A BoolVarOperand is a combination of variables on which the
  # constraints defined in BoolVarConstraintReceiver can be placed.
  #
  # Boolean operands can be created either by using
  # Gecode::Model#bool_var et al, or by using properties that produce
  # boolean operands. The operands, no matter how they were created, 
  # all respond to the properties defined by BoolVarOperand.
  #
  # == Examples
  #
  # Produces a single boolean operand inside a problem formulation,
  # using Gecode::Model#bool_var .
  #
  #   bool_operand = bool_var
  #
  # Uses the BoolVarOperand#& property to produce a new boolean
  # operand representing +bool_operand1+ AND +bool_operand2+.
  #
  #   new_bool_operand = bool_operand1 & bool_operand2
  #
  # Uses the BoolEnumOperand#conjunction property to produce a new
  # boolean operand representing the conjunction of all boolean operands
  # in the enumeration +bool_enum+.
  # 
  #   new_bool_operand = bool_enum.conjunction
  module BoolVarOperand  
    include Gecode::Constraints::Operand 

    def method_missing(method, *args) #:nodoc:
      if Gecode::FreeBoolVar.instance_methods.include? method.to_s
        # Delegate to the bool var.
        to_bool_var.method(method).call(*args)
      else
        super
      end
    end

    private

    def construct_receiver(params)
      BoolVarConstraintReceiver.new(@model, params)
    end
  end

  # BoolVarConstraintReceiver contains all constraints that can be
  # placed on a BoolVarOperand.
  #
  # Constraints are placed by calling BoolVarOperand#must (or any other
  # of the variations defined in Operand), which produces a 
  # BoolVarConstraintReceiver from which the desired constraint can be used.
  #
  # == Examples
  #
  # Constrains +bool_operand+ to be true using
  # BoolVarConstraintReceiver#true .
  #
  #   bool_operand.must_be.true
  #
  # Constrains +bool_operand1+ AND +bool_operand2+ to be true using 
  # the BoolVarOperand#& property and BoolVarConstraintReceiver#true .
  #
  #   (bool_operand1 & bool_operand2).must_be.true
  #
  # Constrains the conjunction of all boolean operands in +bool_enum+ to
  # _not_ imply +bool_operand+ using the 
  # BoolEnumOperand#conjunction property and BoolVarConstraintReceiver#imply .
  #
  #   bool_enum.conjunction.must_not.imply bool_operand
  class BoolVarConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an bool operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_bool_var
        raise TypeError, 'Must have bool operand as left hand side.'
      end
    end
  end

  # An operand that short circuits boolean equality.
  class ShortCircuitEqualityOperand #:nodoc:
    include Gecode::Constraints::Bool::BoolVarOperand
    attr :model

    def initialize(model)
      @model = model
    end

    def construct_receiver(params)
      params.update(:lhs => self)
      receiver = BoolVarConstraintReceiver.new(@model, params)
      op = self
      receiver.instance_eval{ @short_circuit = op }
      class <<receiver
        alias_method :equality_without_short_circuit, :==
        def ==(operand, options = {})
          if !@params[:negate] and options[:reify].nil? and 
              operand.respond_to? :to_bool_var
            # Short circuit the constraint.
            @params.update Gecode::Constraints::Util.decode_options(options)
            @model.add_constraint(Gecode::Constraints::BlockConstraint.new(
                @model, @params) do
              @short_circuit.constrain_equal(operand, false,
                @params.values_at(:strength, :kind))
            end)
          else
            equality_without_short_circuit(operand, options)
          end
        end
        alias_comparison_methods
      end

      return receiver
    end

    def to_bool_var
      variable = model.bool_var
      options = 
        Gecode::Constraints::Util.decode_options({}).values_at(:strength, :kind)
      model.add_interaction do
        constrain_equal(variable, true, options)
      end
      return variable
    end

    private

    # Constrains this operand to equal +bool_variable+ using the
    # specified +propagation_options+. If +constrain_domain+ is true
    # then the method should also attempt to constrain the bounds of the
    # domain of +bool_variable+.
    def constrain_equal(bool_operand, constrain_domain, propagation_options)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end
  end
end

require 'gecoder/interface/constraints/bool/boolean'
require 'gecoder/interface/constraints/bool/linear'
require 'gecoder/interface/constraints/bool/channel'
