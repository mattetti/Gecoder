module Gecode::Constraints::Int
  module IntVarOperand
    # Produces an integer operand representing the absolute value of this 
    # operand.
    #
    # == Examples
    #   
    #   # The absolute value of +int_op+.
    #   int_op.abs
    def abs
      Arithmetic::IntAbsOperand.new(@model, self)
    end
    
    # Produces an integer operand representing this operand squared.
    #
    # == Examples
    #   
    #   # The value of +int_op*int_op+.
    #   int_op.squared
    def squared
      Arithmetic::IntSquaredOperand.new(@model, self)
    end

    # Produces an integer operand representing the square root of this 
    # operand rounded down.
    #
    # == Examples
    #   
    #   # The square root of +int_op+, rounded down.
    #   int_op.square_root
    def sqrt
      Arithmetic::IntSquareRootOperand.new(@model, self)
    end
    alias_method :square_root, :sqrt


    alias_method :pre_arith_mult, :* if instance_methods.include? '*'
    
    # Produces a new integer operand representing this operand times
    # +int_operand+.
    #
    # == Examples
    #   
    #   # The value of +int_op1+ times +int_op2+.
    #   int_op1 * int_op2
    def *(int_operand)
      if int_operand.respond_to? :to_int_var
        Arithmetic::IntMultOperand.new(@model, self, int_operand)
      else
        if respond_to? :pre_arith_mult
          pre_arith_mult(int_operand) 
        else
          raise TypeError, "Expected int operand, got #{int_operand.class}."
        end
      end
    end
  end
  
  # A module that gathers the classes and modules used by arithmetic 
  # constraints.
  module Arithmetic #:nodoc:
    class IntAbsOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, int_op)
        super model
        @int = int_op
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        int_op = @int.to_int_var
        if constrain
          bounds = [int_op.min.abs, int_op.max.abs]
          bounds << 0 if int_op.min < 0
          int_operand.must_be.in bounds.min..bounds.max
        end
        
        Gecode::Raw::abs(@model.active_space, int_op.to_int_var.bind, 
          int_operand.to_int_var.bind, *propagation_options)
      end
    end
    
    class IntMultOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, op1, op2)
        super model
        @op1 = op1
        @op2 = op2
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        int_op1, int_op2 = @op1.to_int_var, @op2.to_int_var
        if constrain
          a_min = int_op1.min; a_max = int_op1.max
          b_min = int_op2.min; b_max = int_op2.max
          products = [a_min*b_min, a_min*b_max, a_max*b_min, a_max*b_max]
          int_operand.must_be.in products.min..products.max
        end

        Gecode::Raw::mult(@model.active_space, int_op1.to_int_var.bind, 
          int_op2.to_int_var.bind, int_operand.to_int_var.bind, 
          *propagation_options)
      end
    end
    
    class IntSquaredOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, int_op)
        super model
        @int = int_op
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        int_op = @int.to_int_var
        if constrain
          min = int_op.min; max = int_op.max
          products = [min*max, min*min, max*max]
          int_operand.must_be.in products.min..products.max
        end

        Gecode::Raw::sqr(@model.active_space, int_op.to_int_var.bind, 
          int_operand.to_int_var.bind, *propagation_options)
      end
    end
    
    class IntSquareRootOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(model, int_op)
        super model
        @int = int_op
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        int_op = @int.to_int_var
        if constrain
          max = int_op.max
          if max < 0
            # The left hand side does not have a real valued square root.
            upper_bound = 0
          else
            upper_bound = Math.sqrt(max).floor;
          end
          
          min = int_op.min
          if min < 0
            lower_bound = 0
          else
            lower_bound = Math.sqrt(min).floor;
          end
          
          int_operand.must_be.in lower_bound..upper_bound
        end

        Gecode::Raw::sqrt(@model.active_space, int_op.to_int_var.bind, 
          int_operand.to_int_var.bind, *propagation_options)
      end
    end
  end
end
