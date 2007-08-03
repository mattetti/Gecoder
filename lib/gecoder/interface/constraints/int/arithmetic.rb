class Gecode::FreeIntVar
  # Initiates an arithmetic absolute value constraint.
  def abs
    Gecode::Constraints::Int::Arithmetic::AbsExpressionStub.new(@model, 
      :lhs => self)
  end

  alias_method :pre_arith_mult, :* if instance_methods.include? '*'
  
  # Begins a multiplication constraint involving the two int variable.
  def *(var)
    if var.kind_of? Gecode::FreeIntVar
      Gecode::Constraints::Int::Arithmetic::MultExpressionStub.new(
        @model, :lhs => self, :var => var)
    else
      pre_arith_mult(var) if respond_to? :pre_arith_mult
    end
  end
end

# A module that gathers the classes and modules used by arithmetic constraints.
module Gecode::Constraints::Int::Arithmetic #:nodoc:
  # Describes a CompositeStub for absolute value constraints, which constrain
  # the absolute value of an integer variable.
  # 
  # == Examples
  #   
  #   # The absolute value of +x+ must be less than 2.
  #   x.abs.must < 2
  #   
  #   # The absolute value of +x+ must be in the range 5..7, with +bool+ as 
  #   # reification variable and +value+ as strength.
  #   x.abs.must_be.in(5..7, :reify => bool, :strength => :value)
  class AbsExpressionStub < Gecode::Constraints::Int::CompositeStub
    def constrain_equal(variable, params, constrain)
      lhs, strength = @params.values_at(:lhs, :strength)
      if constrain
        bounds = [lhs.min.abs, lhs.max.abs]
        variable.must_be.in bounds.min..bounds.max
      end
      
      Gecode::Raw::abs(@model.active_space, lhs.bind, variable.bind, strength)
    end
  end
  
  # Describes a CompositeStub for multiplication constraint, which constrain
  # the value of the multiplication of two variables.
  # 
  # == Examples
  #   
  #   # The value of +x*y+ must be equal to their sum.
  #   (x*y).must == x + y
  #   
  #   # The valye of +x*y+ must be less than 17, with +bool+ as reification 
  #   # variable and +domain+ as strength.
  #   (x*y).must_be.less_than(17, :reify => bool, :strength => :domain)
  class MultExpressionStub < Gecode::Constraints::Int::CompositeStub
    def constrain_equal(variable, params, constrain)
      lhs, lhs2, strength = @params.values_at(:lhs, :var, :strength)
      if constrain
        a_min = lhs.min; a_max = lhs.max
        b_min = lhs2.min; b_max = lhs2.max
        products = [a_min*b_min, a_min*b_max, a_max*b_min, a_max*b_max]
        variable.must_be.in products.min..products.max
      end

      Gecode::Raw::mult(@model.active_space, lhs.bind, lhs2.bind, 
        variable.bind, strength)
    end
  end
end
