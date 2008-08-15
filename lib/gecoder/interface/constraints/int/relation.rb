module Gecode::Constraints::Int
  class IntConstraintReceiver
    # Constrains the integer operand to equal +operand+ (either a
    # constant integer or an integer operand). Negation and reification
    # are supported.
    #
    # === Examples
    #   
    #   # +int1+ must equal +int2+
    #   int1.must == int2
    #
    #   # +int+ must equal 17
    #   int.must == 17
    #   
    #   # +int1+ must equal +int2+. We reify the constraint with 
    #   # +bool+ and select +domain+ as strength.
    #   int1.must.equal(int2, :reify => bool, :strength => :domain)
    def ==(operand, options = {})
      comparison(:==, operand, options)
    end

    # Constrains the integer operand to be strictly greater than
    # +operand+ (either a constant integer or an integer operand).
    # Negation and reification are supported.
    #
    # === Examples
    #   
    #   # +int1+ must be strictly greater than +int2+
    #   int1.must > int2
    #
    #   # +int+ must be strictly greater than 17
    #   int.must > 17
    #   
    #   # +int1+ must be strictly greater than +int2+. We reify the
    #   # constraint with +bool+ and select +domain+ as strength.
    #   int1.must_be.greater_than(int2, :reify => bool, :strength => :domain)
    def >(operand, options = {})
      comparison(:>, operand, options)
    end
    
    # Constrains the integer operand to be greater than or equal to
    # +operand+ (either a constant integer or an integer operand).
    # Negation and reification are supported.
    #
    # === Examples
    #   
    #   # +int1+ must be greater than or equal to +int2+
    #   int1.must >= int2
    #
    #   # +int+ must be greater than or equal to 17
    #   int.must >= 17
    #   
    #   # +int1+ must be greater than or equal to +int2+. We reify the
    #   # constraint with +bool+ and select +domain+ as strength.
    #   int1.must.greater_or_equal(int2, :reify => bool, :strength => :domain)
    def >=(operand, options = {})
      comparison(:>=, operand, options)
    end
    
    # Constrains the integer operand to be strictly less than
    # +operand+ (either a constant integer or an integer operand).
    # Negation and reification are supported.
    #
    # === Examples
    #   
    #   # +int1+ must be strictly less than +int2+
    #   int1.must < int2
    #
    #   # +int+ must be strictly less than 17
    #   int.must < 17
    #   
    #   # +int1+ must be strictly less than +int2+. We reify the
    #   # constraint with +bool+ and select +domain+ as strength.
    #   int1.must_be.less_than(int2, :reify => bool, :strength => :domain)
    def <(operand, options = {})
      comparison(:<, operand, options)
    end
    
    # Constrains the integer operand to be less than or equal to
    # +operand+ (either a constant integer or an integer operand).
    # Negation and reification are supported.
    #
    # === Examples
    #   
    #   # +int1+ must be less than or equal to +int2+
    #   int1.must <= int2
    #
    #   # +int+ must be less than or equal to 17
    #   int.must <= 17
    #   
    #   # +int1+ must be less than or equal to +int2+. We reify the
    #   # constraint with +bool+ and select +domain+ as strength.
    #   int1.must.less_or_equal(int2, :reify => bool, :strength => :domain)
    def <=(operand, options = {})
      comparison(:<=, operand, options)
    end
    
    alias_comparison_methods
    
    private

    # Helper for the comparison methods. The reason that they are not
    # generated in a loop is that it would mess up the RDoc.
    def comparison(name, operand, options)
      unless operand.respond_to?(:to_int_var) or 
          operand.kind_of?(Fixnum)
        raise TypeError, "Expected int operand or integer, got " + 
          "#{operand.class}."
      end

      unless @params[:negate]
        relation_type = Gecode::Constraints::Util::RELATION_TYPES[name]
      else
        relation_type = Gecode::Constraints::Util::NEGATED_RELATION_TYPES[name]
      end
      @params.update Gecode::Constraints::Util.decode_options(options)
      @model.add_constraint Relation::RelationConstraint.new(@model, 
        @params.update(:relation_type => relation_type, :rhs => operand))
    end
  end

  # A module that gathers the classes and modules used in relation constraints.
  module Relation #:nodoc:
    class RelationConstraint < Gecode::Constraints::ReifiableConstraint #:nodoc:
      def post
        # Fetch the parameters to Gecode.
        lhs, relation, rhs, reif_var = 
          @params.values_at(:lhs, :relation_type, :rhs, :reif)
          
        rhs = rhs.to_int_var.bind if rhs.respond_to? :to_int_var
        if reif_var.nil?
          Gecode::Raw::rel(@model.active_space, lhs.to_int_var.bind, 
            relation, rhs, *propagation_options)
        else
          Gecode::Raw::rel(@model.active_space, lhs.to_int_var.bind, 
            relation, rhs, reif_var.to_bool_var.bind, *propagation_options)
        end
      end
    end
  end
end
