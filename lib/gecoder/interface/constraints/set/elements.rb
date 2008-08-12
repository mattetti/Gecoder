module Gecode::Constraints::Set
  module SetVarOperand
    # Produces an operand on which relation constraints can be placed that
    # affect all elements in the set.
    #
    # == Examples
    #
    #   # The elements of +set+.
    #   set.elements
    #
    #   # Constrain all elements of +set+ to be greater than 17.
    #   set.elements.must > 17
    def elements
      params = {:lhs => self}
      Gecode::Constraints::SimpleExpressionStub.new(@model, params) do |m, ps|
        Gecode::Constraints::Set::Relation::ElementExpression.new(m, ps)
      end
    end
  end
    
  module Elements #:nodoc:
    # Describes an element relation constraint which constrains all elements in
    # a set variable to satisfy an integer relation constraint. The relations
    # supported are the same as in 
    # <tt>Int::Linear::SimpleRelationConstraint</tt>.
    # 
    # Reification is not supported.
    # 
    # == Examples
    # 
    #   # All elements in +set+ must be larger than 5.
    #   set.elements.must > 5
    #   
    #   # No element in +set+ may equal 0.
    #   set.elements.must_not == 0
    #   
    #   # No element in +set+ may contain the value of the integer variable
    #   # +forbidden_number+.
    #   set.elements.must_not == forbidden_number
    class ElementRelationConstraint < Gecode::Constraints::Constraint
      def post
        var, rhs, relation = @params.values_at(:lhs, :rhs, :relation)
        
        if @params[:negate]
          type = Gecode::Constraints::Util::NEGATED_RELATION_TYPES[relation]
        else
          type = Gecode::Constraints::Util::RELATION_TYPES[relation]
        end

        if rhs.kind_of? Fixnum
          # Use a proxy int variable to cover.
          rhs = @model.int_var(rhs)
        end
        Gecode::Raw::rel(@model.active_space, var.bind, type, rhs.bind)
      end
    end
    
    # Describes an expression which starts with set.elements.must* .
    class ElementExpression < Gecode::Constraints::Expression #:nodoc:
      Gecode::Constraints::Util::RELATION_TYPES.each_key do |name|
        module_eval <<-"end_code"
          # Creates an elements constraint using the specified expression, which
          # may be either a constant integer of variable.
          def #{name}(expression)
            unless expression.kind_of?(Fixnum) or 
                expression.kind_of?(Gecode::FreeIntVar)
              raise TypeError, "Invalid expression type \#{expression.class}."
            end
            @params.update(:rhs => expression, :relation => :#{name})
            @model.add_constraint ElementRelationConstraint.new(@model, @params)
          end
        end_code
      end
      alias_comparison_methods
    end
  end
end
