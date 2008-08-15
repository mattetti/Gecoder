# A module that deals with the operands, properties and constraints of
# boolean variables.
module Gecode::Constraints::Bool
  # Describes an integer variable operand. Classes that mixes in
  # IntVarOperand must define the method #model and #to_bool_var.
  module BoolVarOperand  
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
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

  # Describes a constraint receiver for boolean variables.
  class BoolVarConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an bool var operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_bool_var
        raise TypeError, 'Must have bool var operand as left hand side.'
      end
    end
  end

  # An operand that short circuits boolean equality.
  class ShortCircuitEqualityOperand
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
