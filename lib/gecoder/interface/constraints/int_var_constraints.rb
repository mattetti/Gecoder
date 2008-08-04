# A module that deals with the operands, properties and constraints of
# integer variables.
module Gecode::Constraints::Int
  # Describes an integer variable operand. Classes that mixes in
  # IntVarOperand must define the method #model.
  module IntVarOperand  
    include Gecode::Constraints::Operand 

    # Constructs an operand that acts as a normal operand but
    # overrides equality so that it is short circuited. 
    #
    # The provided block should accept three parameters. The first is
    # the variable that should represent the operand. The second is the
    # hash of parameters. The third is a boolean, it it's true then the
    # block should try to constrain the first variable's domain as much
    # as possible. The block should constrain the variable to equal the
    # operands value.
    def self.operand_with_short_circuit_equality(model, &block)
      klass = Class.new
      klass.class_eval do
        include Gecode::Constraints::Int::IntVarOperand

        def construct_receiver(params)
          params.update(:lhs => self)
          receiver = IntVarConstraintReceiver.new(@model, params)

          class <<receiver
            alias_method :equality_without_short_circuit, :==
            def ==(operand, options = {})
              if !@params[:negate] and options[:reify].nil? and 
                  operand.respond_to? :to_int_var
                # Short circuit the constraint to avoid a needless
                # constraint.
                @params.update Gecode::Constraints::Util.decode_options(options)
                @model.add_interaction do
                  block.call(operand, @params, false)
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
          variable = @model.int_var
          @model.add_interaction do
            block.call(variable, @params, true)
          end
          return variable
        end
      end

      new_op = klass.new
      new_op.instance_eval do 
        @model = model
      end

      return new_op
    end

    private

    def construct_receiver(params)
      params.update(:lhs => self)
      IntVarConstraintReceiver.new(model, params)
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

require 'gecoder/interface/constraints/int/linear'
require 'gecoder/interface/constraints/int/domain'
#require 'gecoder/interface/constraints/int/arithmetic'
#require 'gecoder/interface/constraints/int/channel'
