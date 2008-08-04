module Gecode::Constraints::Bool
  module BoolVarOperand  
    # Produces a new boolean operand representing this operand OR +bool_op+.
    # 
    # == Examples
    #
    #  # +b1+ and +b2+
    #  b1 & b2
    def |(bool_op)
      ExpressionNode.new(self, @model) | bool_op
    end
    
    # Produces a new boolean operand representing this operand AND +bool_op+.
    #
    # == Examples
    #
    #   # (+b1+ and +b2+) or +b3+ 
    #   (b1 & b1) | b3
    def &(bool_op)
      ExpressionNode.new(self, @model) & bool_op
    end
    
    # Produces a new boolean operand representing this operand XOR +bool_op+.
    #
    # == Examples
    #
    #   # (+b1+ and +b2+) or (+b3+ exclusive or +b1+)
    #   (b1 & b2) | (b3 ^ b1)
    def ^(bool_op)
      ExpressionNode.new(self, @model) ^ bool_op
    end
    
    # Produces a new boolean operand representing that this operand implies
    # +bool_op+.
    #
    # == Examples
    #   
    #   # (+b1+ implies +b2+) and (+b3+ implies +b2+)
    #   (b1.implies b2) & (b3.implies b2)
    def implies(bool_op)
      ExpressionNode.new(self, @model).implies bool_op
    end
  end
  
  class BoolVarConstraintReceiver
    # Constrains the boolean operand to be equal to +bool_op+. Negation and 
    # reification are supported. Any of <tt>==</tt>, +equal+ and +equal_to+ may 
    # be used for equality.
    # 
    # === Examples
    # 
    #   # +b1+ and +b2+ must equal +b1+ or +b2+.
    #   (b1 & b2).must == (b1 | b2)
    #   
    #   # +b1+ and +b2+ must not equal +b3+. We reify it with +bool+ and select 
    #   # the strength +domain+.
    #   (b1 & b2).must_not.equal(b3, :reify => bool, :select => :domain)
    def ==(bool_op, options = {})
=begin
# TODO reenable when integer linear expressions are back.
      if expression.kind_of? Gecode::Constraints::Int::Linear::ExpressionTree
        return expression.must == @params[:lhs]
      end
=end
      unless expression.respond_to? :to_minimodel_bool_expr
        expression = ExpressionNode.new(expression, @model)
      end
      @params.update Gecode::Constraints::Util.decode_options(options)
      @params.update(:lhs => @params[:lhs], :rhs => expression)
      @model.add_constraint BooleanConstraint.new(@model, @params)
    end
    alias_comparison_methods
    
    # Constrains the boolean operand to imply +bool_op+. Negation and reification 
    # are supported.
    # 
    # === Examples
    #   
    #   # +b1+ must imply +b2+
    #   b1.must.imply b2
    #   
    #   # +b1+ and +b2+ must not imply +b3+. We reify it with +bool+ and select
    #   # +domain+ as strength.
    #   (b1 & b2).must_not.imply(b3, :reify => bool, :strength => :domain)
    def imply(bool_op, options = {})
      @params.update Gecode::Constraints::Util.decode_options(options)
      @params.update(:lhs => @params[:lhs].implies(expression), :rhs => true)
      @model.add_constraint BooleanConstraint.new(@model, @params)
    end
    
    # Constrains the boolean operand to be true. Negation and reification are 
    # supported.
    # 
    # === Examples
    # 
    #   # +b1+ and +b2+ must be true.
    #   (b1 & b2).must_be.true
    #   
    #   # (+b1+ implies +b2+) and (+b3+ implies +b2+) must be true.
    #   ((b1.implies b2) & (b3.implies b2)).must_be.true
    # 
    #   # +b1+ and +b2+ must be true. We reify it with +bool+ and select the
    #   # strength +domain+.
    #   (b1 & b2).must_be.true(:reify => bool, :strength => :domain)
    def true(options = {})
      @params.update Gecode::Constraints::Util.decode_options(options)
      @model.add_constraint BooleanConstraint.new(@model, 
        @params.update(:rhs => true))
    end
    
    # Constrains the boolean operand to be false. Negation and reification are 
    # supported.
    #
    # === Examples
    # 
    #   # +b1+ and +b2+ must be false.
    #   (b1 & b2).must_be.false
    #   
    #   # (+b1+ implies +b2+) and (+b3+ implies +b2+) must be false.
    #   ((b1.implies b2) & (b3.implies b2)).must_be.false
    # 
    #   # +b1+ and +b2+ must be false. We reify it with +bool+ and select the
    #   # strength +domain+.
    #   (b1 & b2).must_be.false(:reify => bool, :strength => :domain)
    def false(options = {})
      @params[:negate] = !@params[:negate]
      self.true
    end
  end
  
  class BooleanConstraint < Gecode::Constraints::ReifiableConstraint #:nodoc:
    def post
      lhs, rhs, negate, reif_var = 
        @params.values_at(:lhs, :rhs, :negate, :reif)

      if lhs.respond_to? :to_bool_var
        lhs = ExpressionNode.new(lhs, @model)
      end
      space = (lhs.model || rhs.model).active_space

      bot_eqv = Gecode::Raw::IRT_EQ
      bot_xor = Gecode::Raw::IRT_NQ

      if rhs.respond_to? :to_minimodel_bool_expr
        if reif_var.nil?
          tree = ExpressionTree.new(lhs, 
            Gecode::Raw::MiniModel::BoolExpr::NT_EQV, rhs)
          tree.to_minimodel_bool_expr.post(space, !negate, 
            *propagation_options)
        else
          tree = ExpressionTree.new(lhs, 
            Gecode::Raw::MiniModel::BoolExpr::NT_EQV, rhs)
          var = tree.to_minimodel_bool_expr.post(space, *propagation_options)
          Gecode::Raw::rel(space, var, (negate ? bot_xor : bot_eqv),
            reif_var.to_bool_var.bind, *propagation_options)
        end
      else
        should_hold = !negate & rhs
        if reif_var.nil?
          lhs.to_minimodel_bool_expr.post(space, should_hold, 
            *propagation_options)
        else
          var = lhs.to_minimodel_bool_expr.post(space, *propagation_options)
          Gecode::Raw::rel(space, var, 
            (should_hold ? bot_eqv : bot_xor),
            reif_var.to_bool_var.bind, *propagation_options)
        end
      end
    end
  end

  # A module containing the methods for the basic boolean operations. Depends
  # on that the class mixing it in defined #model.
  module OperationMethods #:nodoc
    include BoolVarOperand

    private
  
    # Maps the names of the methods to the corresponding bool constraint in 
    # Gecode.
    OPERATION_TYPES = {
      :|        => Gecode::Raw::MiniModel::BoolExpr::NT_OR,
      :&        => Gecode::Raw::MiniModel::BoolExpr::NT_AND,
      :^        => Gecode::Raw::MiniModel::BoolExpr::NT_XOR,
      :implies  => Gecode::Raw::MiniModel::BoolExpr::NT_IMP
    }
    
    public
    
    OPERATION_TYPES.each_pair do |name, operation|
      module_eval <<-"end_code"
        def #{name}(expression)
          unless expression.kind_of? ExpressionTree
            expression = ExpressionNode.new(expression)
          end
          ExpressionTree.new(self, #{operation}, expression)
        end
      end_code
    end
    
    private
    
    # Produces a receiver (for the BoolVarOperand module).
    def construct_receiver(params)
      params.update(:lhs => self)
      BoolVarConstraintReceiver.new(model, params)
    end
  end

  # Describes a binary tree of expression nodes which together form a boolean 
  # expression.
  class ExpressionTree #:nodoc:
    include OperationMethods
  
    # Constructs a new expression with the specified binary operation 
    # applied to the specified trees.
    def initialize(left_tree, operation, right_tree)
      @left = left_tree
      @operation = operation
      @right = right_tree
    end
    
    # Returns a MiniModel boolean expression representing the tree.
    def to_minimodel_bool_expr
      Gecode::Raw::MiniModel::BoolExpr.new(
        @left.to_minimodel_bool_expr, @operation, 
        @right.to_minimodel_bool_expr)
    end
    
    # Fetches the space that the expression's variables is in.
    def model
      @left.model || @right.model
    end
  end

  # Describes a single node in a boolean expression.
  class ExpressionNode #:nodoc:
    include OperationMethods
  
    attr :model
  
    def initialize(value, model = nil)
      unless value.respond_to? :to_bool_var        
        raise TypeError, 'Invalid type used in boolean equation: ' +
          "#{value.class}."
      end
      @value = value
      @model = model
    end
    
    # Returns a MiniModel boolean expression representing the tree.
    def to_minimodel_bool_expr
      Gecode::Raw::MiniModel::BoolExpr.new(@value.to_bool_var.bind)
    end
  end
end
