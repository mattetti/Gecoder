# A module containing constraints that have set variables as left hand side
# (but not enumerations).
module Gecode::Constraints::Set
  # Describes a set variable operand. Classes that mix in
  # SetVarOperand must define the method #model and #to_set_var.
  module SetVarOperand  
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
      if Gecode::FreeSetVar.instance_methods.include? method.to_s
        # Delegate to the set var.
        to_set_var.method(method).call(*args)
      else
        super
      end
    end

    private

    def construct_receiver(params)
      SetVarConstraintReceiver.new(model, params)
    end
  end

  # An operand that short circuits set equality.
  class ShortCircuitEqualityOperand
    include Gecode::Constraints::Set::SetVarOperand
    attr :model

    def initialize(model)
      @model = model
    end

    def construct_receiver(params)
      params.update(:lhs => self)
      receiver = SetVarConstraintReceiver.new(@model, params)
      op = self
      receiver.instance_eval{ @short_circuit = op }
      class <<receiver
        alias_method :equality_without_short_circuit, :==
        def ==(operand, options = {})
          if !@params[:negate] and !options.has_key?(:reify) and 
              operand.respond_to? :to_set_var
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

    def to_set_var
      variable = model.set_var
      model.add_interaction do
        constrain_equal(variable, true, 
          [Gecode::Raw::ICL_DEF, Gecode::Raw::PK_DEF])
      end
      return variable
    end

    private

    # Constrains this operand to equal +set_variable+ using the
    # specified +propagation_options+. If +constrain_domain+ is true
    # then the method should also attempt to constrain the bounds of the
    # domain of +set_variable+.
    def constrain_equal(set_operand, constrain_domain, propagation_options)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end
  end

  # An operand that short circuits set non-negated and non-reified versions 
  # of the relation constraints.
  class ShortCircuitRelationsOperand
    include Gecode::Constraints::Set::SetVarOperand
    attr :model

    def initialize(model)
      @model = model
    end

    def construct_receiver(params)
      params.update(:lhs => self)
      receiver = SetVarConstraintReceiver.new(@model, params)
      op = self
      receiver.instance_eval{ @short_circuit = op }
      class <<receiver
        Gecode::Constraints::Util::SET_RELATION_TYPES.keys.each do |comp|
          eval <<-end_code
            alias_method :alias_#{comp.to_i}_without_short_circuit, :#{comp}
            def #{comp}(operand, options = {})
              if !@params[:negate] && !options.has_key?(:reify) && 
                  (operand.respond_to?(:to_set_var) or 
                  Gecode::Constraints::Util::constant_set?(operand))
                # Short circuit the constraint.
                @params.update Gecode::Constraints::Util.decode_options(options)
                @model.add_constraint(
                  @short_circuit.relation_constraint(
                    :#{comp}, operand, @params))
              else
                alias_#{comp.to_i}_without_short_circuit(operand, options)
              end
            end
          end_code
        end
        alias_comparison_methods
      end

      return receiver
    end

    def to_set_var
      variable = model.set_var
      model.add_interaction do
        constrain_equal variable
      end
      return variable
    end

    # Returns a constraint that constrains this operand to have relation
    # +relation+ to +set_operand_or_constant_set+, which is either a set
    # operand or a constant set, given the specified hash +params+ of 
    # parameters. The constraints are never negated nor reified.
    def relation_constraint(relation, set_operand_or_constant_set, params)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end

    private

    # Constrains this operand to equal +set_variable+.
    def constrain_equal(set_variable)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end
  end

  # Describes a constraint receiver for set variables.
  class SetVarConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an set var operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_set_var
        raise TypeError, 'Must have set var operand as left hand side.'
      end
    end
  end

  # Utility methods for sets.
  module Util #:nodoc:
    module_function
    def decode_options(options)
      if options.has_key? :strength
        raise ArgumentError, 'Set constraints do not support the strength ' +
          'option.'
      end
      if options.has_key? :kind
        raise ArgumentError, 'Set constraints do not support the kind ' +
          'option.'
      end
      
      Gecode::Constraints::Util.decode_options(options)
    end
  end
end

require 'gecoder/interface/constraints/set/domain'
require 'gecoder/interface/constraints/set/relation'
require 'gecoder/interface/constraints/set/cardinality'
require 'gecoder/interface/constraints/set/connection'
#require 'gecoder/interface/constraints/set/include'
require 'gecoder/interface/constraints/set/operation'
#require 'gecoder/interface/constraints/set/channel'
