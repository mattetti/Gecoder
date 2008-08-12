module Gecode::Constraints::Set
  class Expression
    # Adds a constraint that forces specified values to be included in the 
    # set. This constraint has the side effect of sorting the variables in 
    # non-descending order.
    def include(variables)
      unless variables.respond_to? :to_int_var_array
        raise TypeError, "Expected int var enum, got #{variables.class}."
      end
      if @params[:negate]
        raise Gecode::MissingConstraintError, 'A negated include is not ' + 
          'implemented.'
      end
      
      @params.update(:variables => variables)
      @model.add_constraint Connection::IncludeConstraint.new(@model, @params)
    end
  end

  # Describes an include constraint, which constrains the set to include the
  # values of the specified enumeration of integer variables. 
  # 
  # The constraint has the side effect of sorting the integer variables in a 
  # non-descending order. It does not support reification nor negation.
  # 
  # == Examples
  # 
  #   # Constrain +set+ to include the values of all variables in 
  #   # +int_enum+.
  #   set.must.include int_enum 
  class IncludeConstraint < Gecode::Constraints::Constraint
    def post
      set, variables = @params.values_at(:lhs, :variables)
      Gecode::Raw::match(@model.active_space, set.bind, 
                         variables.to_int_var_array)
    end
  end
end
