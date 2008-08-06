# A module that deals with the operands, properties and constraints of
# integer variables.
module Gecode::Constraints::Int
  # Describes an integer variable operand. Classes that mixes in
  # IntVarOperand must define the method #model and #to_int_var.
  module IntVarOperand  
    include Gecode::Constraints::Operand 

    def method_missing(method, *args)
      if Gecode::FreeIntVar.instance_methods.include? method.to_s
        # Delegate to the int var.
        to_int_var.method(method).call(*args)
      else
        super
      end
    end

    private

    def construct_receiver(params)
      params.update(:lhs => self)
      IntVarConstraintReceiver.new(model, params)
    end
  end

  # An operand that short circuits integer equality.
  class ShortCircuitEqualityOperand
    include Gecode::Constraints::Int::IntVarOperand
    attr :model

    def initialize(model)
      @model = model
    end

    def construct_receiver(params)
      params.update(:lhs => self)
      receiver = IntVarConstraintReceiver.new(@model, params)
      op = self
      receiver.instance_eval{ @short_circuit = op }
      class <<receiver
        alias_method :equality_without_short_circuit, :==
        def ==(operand, options = {})
          if !@params[:negate] and options[:reify].nil? and 
              operand.respond_to? :to_int_var
            # Short circuit the constraint.
            @params.update Gecode::Constraints::Util.decode_options(options)
            @model.add_interaction do
              @short_circuit.constrain_equal(operand, false,
                @params.values_at(:strength, :kind))
            end
          else
            equality_without_short_circuit(operand, options)
          end
        end
        alias_comparison_methods
      end

      return receiver
    end

    def to_int_var
      variable = model.int_var
      model.add_interaction do
        constrain_equal(variable, true, 
          [Gecode::Raw::ICL_DEF, Gecode::Raw::PK_DEF])
      end
      return variable
    end

    private

    # Constrains this operand to equal +int_variable+ using the
    # specified +propagation_options+. If +constrain_domain+ is true
    # then the method should also attempt to constrain the bounds of the
    # domain of +int_variable+.
    def constrain_equal(int_operand, constrain_domain, propagation_options)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end
  end

  # An operand that short circuits integer relation constraints.
  class ShortCircuitRelationsOperand
    include Gecode::Constraints::Int::IntVarOperand
    attr :model

    def initialize(model)
      @model = model
    end

    def construct_receiver(params)
      params.update(:lhs => self)
      receiver = IntVarConstraintReceiver.new(@model, params)
      op = self
      receiver.instance_eval{ @short_circuit = op }
      class <<receiver
        Gecode::Constraints::Util::COMPARISON_ALIASES.keys.each do |comp|
          eval <<-end_code
            alias_method :alias_#{comp.to_i}_without_short_circuit, :#{comp}
            def #{comp}(operand, options = {})
              if operand.respond_to?(:to_int_var) or operand.kind_of? Fixnum
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

    def to_int_var
      variable = model.int_var
      model.add_interaction do
        constrain_equal variable
      end
      return variable
    end

    # Returns a constraint that constrains this operand to have relation
    # +relation+ to +int_operand_or_fix+, which is either an integer 
    # operand or a fixnum, given the specified hash +params+ of parameters.
    def relation_constraint(relation, int_operand_or_fix, params)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end

    private

    # Constrains this operand to equal +int_variable+.
    def constrain_equal(int_variable)
      raise NotImplementedError, 'Abstract method has not been implemented.'
    end
  end

  # Describes a constraint receiver for integer variables.
  class IntVarConstraintReceiver < Gecode::Constraints::ConstraintReceiver
    # Raises TypeError unless the left hand side is an int var operand.
    def initialize(model, params)
      super

      unless params[:lhs].respond_to? :to_int_var
        raise TypeError, 'Must have int var operand as left hand side.'
      end
    end
  end
  
=begin
  # A composite expression which is an int expression with a left hand side 
  # resulting from a previous constraint.
  class CompositeExpression < Gecode::Constraints::CompositeExpression #:nodoc:
    # The block given should take three parameters. The first is the variable 
    # that should be the left hand side, if it's nil then a new one should be
    # created. The second is the has of parameters. The block should return 
    # the variable used as left hand side.
    def initialize(model, params, &block)
      super(Expression, Gecode::FreeIntVar, lambda{ model.int_var }, model, 
        params, &block)
    end

    # Converts the expression into an instance of Gecode::FreeIntVar.
    def to_int_var
      # Link a variable to the composite constraint.
      variable = @new_var_proc.call
      @model.add_interaction do
        @constrain_equal_proc.call(variable, @params, true)
      end
      return variable
    end
  end
  
  # Describes a stub that produces an int variable, which can then be used 
  # with the normal int variable constraints. An example would be the element
  # constraint.
  #
  #   int_enum[int_var].must > rhs
  #
  # <tt>int_enum[int_var]</tt> produces an int variable which the constraint 
  # <tt>.must > rhs</tt> is then applied to. In the above case two 
  # constraints (and one temporary variable) are required, but in the case of 
  # equality only one constraint is required.
  # 
  # Whether a constraint involving a reification stub supports negation, 
  # reification, strength options and so on depends on the constraint on the
  # right hand side.
  class CompositeStub < Gecode::Constraints::CompositeStub
    def initialize(model, params)
      super(CompositeExpression, model, params)
    end
  end
=end
end

require 'gecoder/interface/constraints/int/relation'
require 'gecoder/interface/constraints/int/linear'
require 'gecoder/interface/constraints/int/domain'
#require 'gecoder/interface/constraints/int/arithmetic'
#require 'gecoder/interface/constraints/int/channel'
